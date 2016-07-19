part of dartdap;

/// LDAP configuration.
///
/// This library should be deprecated, since a library should not have
/// dependencies on configuration files - it should be up to the application
/// to choose where it obtains its configuration parameters from.
///
/// It is only used by the tests.
///
/// A LDAP configuration settings and a LDAP connection created from it.
///
/// Use an instance of this class to represent the LDAP server
/// settings (host, port, bind distinguished name, password, and
/// whether the connection uses TLS/SSL).
///
/// It is also used to obtain an [LdapConnection] using those settings.
///
/// There are two ways to create an LDAP configuration:
///
/// * Providing the settings as parameters using the default constructor.
/// * Loading the settings from a YAML file using the fromFile constructor.

class LDAPConfiguration {
  // Constants

  static const String _DEFAULT_HOST = "localhost";
  static const int _STANDARD_LDAP_PORT = 389;
  static const int _STANDARD_LDAPS_PORT = 636;

  // Configuration settings

  /// The LDAP server hostname or IP address
  String host;

  /// The LDAP server port number
  int port;

  /// Whether the connection to the LDAP server uses TLS/SSL
  bool ssl;

  /// The distinguished name of the entry for the bind operation
  String bindDN;

  /// The password used for the bind operation
  String password;

  // File details (only set if object created by the fromFile constructor)

  bool _file_load; // true if settings need to be loaded from file
  String _file_name; // file containing settings
  String _file_entry; // name of map in the YAML settings file

  // Cached connection

  LdapConnection _connection; // null if not created

  // Set values
  //
  // This internal method is used by the default constructor and to
  // process settings loaded from a file. It applies all the default rules
  // for when values are not provided.

  void _setAll(
      String hostname, int port, bool ssl, String bindDN, String password) {
    this.host = (hostname != null) ? hostname : _DEFAULT_HOST;
    this.ssl = (ssl != null) ? ssl : false;
    this.port = (port != null)
        ? port
        : ((this.ssl) ? _STANDARD_LDAPS_PORT : _STANDARD_LDAP_PORT);
    this.bindDN = (bindDN != null) ? bindDN : "";
    this.password = (password != null) ? password : "";
  }

  /// Constructor for a new LDAP configuration.
  ///
  /// The [hostname] is the hostname of the LDAP server.
  ///
  /// The [port] is the port number of the LDAP server. It defaults to the
  /// standard LDAP port numbers: 389 when TLS is not used or 636 when TLS is
  /// used.
  ///
  /// Set [ssl] to true to connect over TLS, otherwise TLS is not used. It
  /// defaults to false.
  ///
  /// Set [bindDN] to the distinguish name for the bind. An empty string
  /// means to perform an anonymous bind.  It defaults to an empty string.
  ///
  /// Set [password] to the password for bind. It defaults to an empty string.
  ///
  /// To perform an anonymous bind, omit the [bindDN] and [password].
  ///
  /// Examples:
  ///
  ///      // Anonymous bind
  ///      LDAPConfiguration.settings("localhost");
  ///      LDAPConfiguration.settings("ldap.example.com", ssl: true);
  ///
  ///      // Authenticated bind
  ///      LDAPConfiguration.settings("ldap.example.com", ssl: true, bindDN: "cn=admin,dc=example,dc=com", password: "p@ssw0rd");

  @deprecated
  LDAPConfiguration(String hostname,
      {int port, bool ssl: false, String bindDN, String password}) {
    _setAll(hostname, port, ssl, bindDN, password);
    _file_load = false;
  }

  /// Constructor for a new LDAP configuration from a YAML file.
  ///
  /// The [fileName] is the name of a YAML file
  /// containing the LDAP connection settings.
  ///
  /// The [configName] is the name of a Map in the YAML file.
  ///
  /// # Example
  ///
  ///     var ldapConfig = new LDAPConfiguration("ldap.yaml", "default");
  ///
  /// This example loads the LDAP configuration from a Map named "default" from
  /// the YAML file "ldap.yaml" in the current directory. That YAML file could
  /// contain:
  ///
  ///     default:
  ///       host: "ldap.example.com"
  ///       port: 389
  ///       ssl: false
  ///       bindDN: "cn=admin,dc=example,dc=com"
  ///       password: "p@ssw0rd"
  ///
  ///  The only mandatory attribute is "host". See the default constructor
  ///  for a description of the other attributes, and their values if they are not specified.

  @deprecated
  LDAPConfiguration.fromFile(String fileName, String configName) {
    assert(fileName != null && fileName.isNotEmpty);
    assert(configName != null && configName.isNotEmpty);

    this._file_name = fileName;
    this._file_entry = configName;
    this._file_load = true;
  }

  /// Loads the settings from the YAML file, if needed.
  ///
  /// If the LDAPConfiguration was not created using the fromFile constructor, this method
  /// does nothign and returns immediately.

  Future _load_values() async {
    if (_file_load == false) {
      // File does not need to be loaded: settings are already set
      // This occurs if the fromFile constructor was not used, or the settings
      // were loaded in a previous invocation of _load_values.
    } else {
      // Load settings from file

      if (_file_name == null || _file_entry == null) {
        assert(false); // this should never happen: can't load from file
        return;
      }

      var configMap = await server_config.loadConfig(_file_name);

      var m = configMap[_file_entry];

      if (m == null) {
        throw new LdapConfigException(
            "${_file_name}: missing \"${_file_entry}\"");
      }
      if (!(m is Map)) {
        throw new LdapConfigException(
            "${_file_name}: \"${_file_entry}\" is not a map");
      }

      // Get and check the host

      var host_value = m["host"];
      if (host_value == null) {
        throw new LdapConfigException(
            "${_file_name}: \"${_file_entry}\" missing \"host\"");
      }
      if (!(host_value is String)) {
        throw new LdapConfigException(
            "${_file_name}: host in \"${_file_entry}\" is not a string");
      }

      // Get and check the port

      var port_value = m["port"];
      if (port_value != null && !(port_value is int)) {
        throw new LdapConfigException(
            "${_file_name}: port in \"${_file_entry}\" is not an int");
      }

      // Get and check the ssl

      var ssl_value = m["ssl"];
      if (ssl_value != null && !(ssl_value is bool)) {
        throw new LdapConfigException(
            "${_file_name}: ssl in \"${_file_entry}\" is not true/false");
      }

      // Get and check bindDN

      var bindDN_value = m["bindDN"];
      if (bindDN_value != null && !(bindDN_value is String)) {
        throw new LdapConfigException(
            "${_file_name}: bindDN in \"${_file_entry}\" is not a string");
      }

      // Get and check password

      var password_value = m["password"];
      if (password_value != null && !(password_value is String)) {
        throw new LdapConfigException(
            "${_file_name}: password in \"${_file_entry}\" is not a string");
      }

      this._setAll(
          host_value, port_value, ssl_value, bindDN_value, password_value);

      _file_load = false; // prevent future invocations from reloading it
    }
  }

  /// Return a Future<[LdapConnection]> using this configuration.
  ///
  /// The connection is cached so that subsequent calls will return
  /// the same connection (unless it has been closed, in which case
  /// a new one will be created).
  ///
  /// If the optional parameter [doBind] is true (the default),
  /// the returned connection will also be bound using the configured DN and password.
  ///
  /// The LDAP connection can be closed by invoking the `close` method on the
  /// [LDAPConfiguration] or by invoking the [LdapConnection.close] method on the
  /// connection object.  Either approach will cause subsequent calls to
  /// this getConnection method to open a new LDAP connection.
  ///
  /// If the host is not resolvable, a [SocketException] is thrown
  /// with osError.errorCode of 8 (nodename nor servname provided, or not known).
  ///
  /// If the host is resolvable, but the port cannot be contacted, a
  /// [SocketException] is thrown with osError.errorCode of 61 (Connection refused).
  ///
  /// If the protocol handshake is not recognised, a [HandshakeException] is
  /// thrown. For example, this happens when trying to establish a LDAPS
  /// connection to a LDAP service. Note: trying to establish a LDAP
  /// connection to a LDAPS service hangs and timesout.

  @deprecated
  Future<LdapConnection> getConnection([bool doBind = true]) async {

    // TODO: delete this class. Its purpose is no longer useful
    // for caching connections, since LDAPConnection now supports automatic
    // opening of closed connections and automatic re-opening of disconnected
    // connections.

    if (_connection != null && _connection.state != LdapConnectionState.connected) {
      // Use cached connection
      return _connection;
    }

    // Get settings (loading them from the YAML file if necessary)

    await _load_values();

    // Connect

    _connection = new LdapConnection(
        host: host,
        ssl: ssl,
        port: port,
        bindDN: bindDN,
        password: password,
        autoConnect: false);

    await _connection.open();

    // Bind

    if (doBind) {
      var r = await _connection.bind();
      assert(r.resultCode == 0); // otherwise an exception was thrown
    }

    return _connection;
  }

  /// Closes the [LDAPconnection] that was opened with getConnection.

  @deprecated
  Future close([bool immediate = false]) {
    if (_connection != null) {
      var f = _connection.close(immediate);
      _connection = null;
      return f;
    } else {
      assert(_connection != null);
      return null;
    }
  }

  /// Returns a string representation of this object.

  @deprecated
  String toString() {
    return "${ssl ? "ldaps://" : "ldap://"}${host}:${port}${(bindDN != null) ? "/${bindDN}" : ""}";
  }
}
