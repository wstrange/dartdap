part of dartdap;

/// Operations that we can invoke on an LDAP server
///
/// ## Usage
///
/// Use the [connect] method to connect to the LDAP server, perform operations,
/// and [close] the connection when finished with it.
///
/// If authentication is required, perform a [bind] operation. Otherwise, the
/// operations will be performed anonymously.
///
/// ## LDAP operations
///
/// Available LDAP operations are:
///
/// - [add]
/// - [bind] - to authenticate to the LDAP server
/// - [compare]
/// - [delete]
/// - [modify]
/// - [modifyDN]
/// - [search]
///
/// All of these methods return an [LDAPResult] object in a [Future], but usually
/// it can be ignored.
///
/// The result's resultCode value will always be either [ResultCode.OK],
/// [ResultCode.COMPARE_FALSE] or [ResultCode.COMPARE_TRUE] - with the last two
/// values only occuring when performing a _compare_ operation.  If the
/// resultCode is any other value, instead of returning the result, a subclass
/// of [LdapResultException] will be thrown. So the returned resultCode does not
/// provide any useful information, except in the case of the _compare_ operation.
///
/// ## Asynchronicity
///
/// With the exception of a _bind_ operation, LDAP operations
/// are asynchronous. A program does not need to wait for the current
/// operation to complete before sending the next one.
///
/// LDAP return results are matched to requests using a message id. They
/// are not guaranteed to be returned in the same order they were sent.
///
/// There is currently no flow control. Messages will be queued and sent
/// to the LDAP server as fast as possible. Messages are sent in in the order in
/// which they are queued.

class LDAPConnection {
  static const String _defaultHost = "localhost";
  static const int defaultPortLdap = 389;
  static const int defaultPortLdaps = 636;

  ConnectionManager _cmgr;

  String _bindDN;
  String _password;

  Function onError; // global error handler

  bool isClosed() => (_cmgr == null || _cmgr.isClosed());

  /**
   * Create a new LDAP connection to [host] and [port].
   *
   * If [ssl] is true the connection will use SSL.
   *
   */
  LDAPConnection(String host, {bool ssl: false, int port: null}) {
    if (host == null || host is! String || host.isEmpty) {
      host = _defaultHost;
    }
    if (ssl == null || ssl is! bool) {
      ssl = false;
    }
    if (port == null || port is! int) {
      port = (ssl) ? defaultPortLdaps : defaultPortLdap; // use default port
    }

    _cmgr = new ConnectionManager(host, port, ssl);
  }

  /// Establishes a connection to the LDAP server without binding to it.
  ///
  /// This does **not** perform a BIND operation.
  ///
  /// See [ConnectionManager.connect] for exceptions thrown.
  ///
  /// If the LDAP server supports anonymous _bind_, LDAP commands can be sent
  /// after the connect completes.

  Future<LDAPConnection> connect() async {
    await _cmgr.connect();
    return this;
  }

  /// Perform an LDAP BIND using the supplied [bindDN] and [password].
  ///
  /// If the [bindDN] is null an anonymous bind is performed.
  ///
  /// The bind DN and password are saved in the [LDAPConnection] object
  /// for subsequent re-connections.

  Future<LDAPResult> bind([String bindDN = null, String password = null]) {
    if (bindDN == null || bindDN is! String || bindDN.isEmpty) {
      // No bind DN: perform anonymous bind

      this._bindDN = "";
      this._password = "";
    } else {
      // Explicit bind

      this._bindDN = bindDN;

      if (password == null || password is! String) {
        this._password = "";
      } else {
        this._password = password;
      }
    }

    return _cmgr.process(new BindRequest(this._bindDN, this._password));
  }

  /// Performs an LDAP search operation.
  ///
  /// Searches for LDAP entries, starting at the [baseDN],
  /// specified by the search [filter], and obtains the listed [attributes].
  ///
  /// The [scope] of the search defaults to SUB_LEVEL (i.e.
  /// search at base DN and all objects below it) if it is not provided.
  ///
  /// The [sizeLimit] defaults to 0 (i.e. no limit).
  ///
  /// An optional list of [controls] can also be provided.
  ///
  /// Example:
  ///
  ///     var base = "dc=example,dc=com";
  ///     var filter = Filter.present("objectClass");
  ///     var attrs = ["dc", "objectClass"];
  ///
  ///     await for (var entry in connection.search(base, filter, attrs).stream) {
  ///       // process the entry (SearchEntry)
  ///       // entry.dn = distinguished name (String)
  ///       // entry.attributes = attributes returned (Map<String,Attribute>)
  ///     }

  SearchResult search(String baseDN, Filter filter, List<String> attributes,
          {int scope: SearchScope.SUB_LEVEL,
          int sizeLimit: 0,
          List<Control> controls: null}) =>
      _cmgr.processSearch(
          new SearchRequest(baseDN, filter, attributes, scope, sizeLimit),
          controls);

  /**
   * Add a new LDAP entry.
   * [dn] is the LDAP Distinguised Name.
   * [attrs] is a map of attributes keyed by the attribute name. The
   *   attribute values can be simple Strings, lists of strings,
   *   or alternatively can be of type [Attribute]
   */

  Future<LDAPResult> add(String dn, Map<String, dynamic> attrs) =>
      _cmgr.process(new AddRequest(dn, Attribute.newAttributeMap(attrs)));

  /// Delete the ldap entry identified by [dn]
  Future<LDAPResult> delete(String dn) => _cmgr.process(new DeleteRequest(dn));

  /// Modify the ldap entry [dn] with the list of modifications [mods]
  Future<LDAPResult> modify(String dn, Iterable<Modification> mods) =>
      _cmgr.process(new ModifyRequest(dn, mods));

  /// Modify the Entries [dn] to a new relative [rdn]. If [deleteOldRDN] is true
  /// delete the old entry. If [newSuperior] is not null, reparent the entry
  /// todo: consider making optional args as named args
  Future<LDAPResult> modifyDN(String dn, String rdn,
          [bool deleteOldRDN = true, String newSuperior]) =>
      _cmgr.process(new ModDNRequest(dn, rdn, deleteOldRDN, newSuperior));

  /// perform an LDAP Compare operation on the [dn].
  /// Compare the [attrName] and [attrValue] to see if they are the same
  ///
  /// The completed [LDAPResult] will have a value of [ResultCode.COMPARE_TRUE]
  /// or [ResultCode.COMPARE_FALSE].
  Future<LDAPResult> compare(String dn, String attrName, String attrValue) =>
      _cmgr.process(new CompareRequest(dn, attrName, attrValue));

  // close the ldap connection. If [immediate] is true, close the
  // connection immediately. This could result in queued operations
  // being discarded
  close([bool immediate = false]) async {
    await _cmgr.close(immediate);
    _cmgr = null;
  }
}
