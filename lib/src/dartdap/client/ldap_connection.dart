part of dartdap;

/// Connection to perform LDAP operations on an LDAP server.
///
/// There are two modes: automatic and manual.  Most programs will use the
/// default automatic mode. The mode is set by the constructor or changed using
/// the [setAutomaticMode] method.
///
/// ## Properties
///
/// An LdapConnection is defined by the network connection and the LDAP binding.
///
/// The network connection is determined by the hostname, whether SSL/TLS is
/// used or not, and the port number.  These are set by the constructor or
/// changed using the [setHost] and [setProtocol] methods.
///
/// The LDAP binding is either anonymous or authenticated.  It is set by the
/// constructor or changed using the [setAuthentication] and [setAnonymous]
/// methods.
///
/// ## Connection management
///
/// ### State
///
/// The state of the LdapConnection can be determined by examining its [state].
///
/// ### Automatic mode vs manual mode
///
/// In automatic mode, the management of opening the network connection and
/// establishing the LDAP binding is handled automatically. The application
/// simply has to create the LdapConnection, perform LDAP operations on it, and
/// close it when finished. The application does not have to explicitly open the
/// network connection or send LDAP BIND requests, unless it wants to.
///
/// In manual mode, the application must explicitly [open] the network
/// connection and use [bind] to send LDAP BIND requests, to make the
/// LdapConnection ready to perform LDAP operations.
///
/// ### Disconnections
///
/// An open network connection can be disconnected by external causes, which are
/// outside the control of the application.  For example, disconnections occur
/// when: the LDAP server times out the connection, the LDAP server is
/// re-started, or network errors causes the connection to be dropped.
///
/// In automatic mode, the application does not have to worry about
/// disconnections. In automatic mode, the LdapConnection will be automatically
/// re-opened (and re-established any LDAP bindings) if it becomes disconnected.
/// Automatic mode was designed to support long-lived connection pooling.
///
/// In manual mode LDAP operations will fail if the LdapConnection becomes
/// disconnected.
///
/// ## LDAP operations
///
/// The available LDAP operations are:
///
/// - [search] - queries the LDAP directory for entries
/// - [compare] - compares values in LDAP entries
/// - [add] - creates a new LDAP entry
/// - [delete] - removes an existing LDAP entry
/// - [modify] - changes attributes in an LDAP entry
/// - [modifyDN] - moves an LDAP entry
///
/// ### Results and exceptions
///
/// All of these methods return a [Future] to an [LdapResult].
///
/// The [LdapResult] contains a _resultCode_ value that will always be either
/// [ResultCode.OK], [ResultCode.COMPARE_FALSE] or [ResultCode.COMPARE_TRUE].
/// The last two values only occur when performing a _compare_ operation.  For
/// all other operations, the _resultCode_ does not carry useful information,
/// because errors will cause an exception to be thrown.
///
/// Exceptions thrown are all subclasses of [LdapResultException].
///
/// ### Asynchronicity
///
/// All these LDAP operations
/// are asynchronous. A program does not need to wait for the current
/// operation to complete before sending the next one.
///
/// Special care must be taken with the [bind] operation in manual mode.  If
/// subsequent operations are to be performed with those LDAP bindings, the
/// application should wait for the Future returned by _bind_ to complete before
/// performing the next operation. In automatic mode, this ordering is always
/// enforced (when _bind_ is explicitly called, and when the LDAP BIND request
/// is automatically sent).
///
/// LDAP return results are matched to requests using a message id. They
/// are not guaranteed to be returned in the same order they were sent.
///
/// There is currently no flow control. Messages will be queued and sent
/// to the LDAP server as fast as possible. Messages are sent in in the order in
/// which they are queued.
///
/// ## Closing
///
/// When finished with the LdapConnection, [close] it.

class LdapConnection {
  //================================================================
  // Static constants

  /// Standard port for LDAP connections (i.e. without TLS/SSL).
  ///
  static const int portLdap = 389;

  /// Standard port for LDAPS connections (LDAP over TLS/SSL).
  ///
  static const int portLdaps = 636;

  //================================================================
  // Members

  /// The underlying connection manager.
  ///
  _ConnectionManager _cmgr;

  //----------------------------------------------------------------
  /// Mode (automatic or manual)
  ///
  bool _autoConnect = true;

  //----------------
  /// Indicates if the connection is in automatic mode or manual mode.
  ///
  /// Value is true if in automatic mode. Otherwise, value is false,
  /// for manual mode.
  ///
  /// This value is initially set by the constructor and can be changed using
  /// the [setAutomaticMode] method.
  ///
  bool get isAutomatic => _autoConnect;

  //----------------
  /// Sets automatic or manual mode.
  ///
  /// The [newValue] must be a boolean that indicates the new mode: true
  /// for automatic mode and false for manual mode.
  ///
  /// The mode can be set when the connection is in any state. The [state] of
  /// the connection is not changed when the mode is changed -- except in one
  /// situation: when it is in manual mode, being changed to automatic mode, and
  /// the state is [ConnectionState.bindRequired]. In that situation, the
  /// state is automatically changed to [ConnectionState.ready] by sending
  /// the required LDAP BIND request. This ensures the _bindRequired_ state
  /// never occurs in automatic mode.
  ///
  /// If the connection was already in the new mode, no change is made.
  ///
  /// Returns a Future which completes immediately if a BIND request does not
  /// need to be sent and value is null; or completes when the BIND request is
  /// finished and the value is the LDAP result from the BIND request.
  ///
  Future<LdapResult> setAutomaticMode(bool newValue) async {
    if (newValue == null) {
      throw new ArgumentError.notNull("autoConnect");
    }
    if (!newValue is bool) {
      throw new ArgumentError.value(newValue, "autoConnect", "not a bool");
    }

    var result = null;

    if (newValue != _autoConnect) {
      if (state == ConnectionState.bindRequired) {
        assert(!_autoConnect); // must have been in manual mode
        result = await _sendBind(onlyIfNecessary: true);
      }
      _autoConnect = newValue;
    }

    return result;
  }

  //----------------------------------------------------------------
  // Hostname

  static const String _defaultHost = "localhost";

  String _host = _defaultHost;

  //----------------
  /// Host name of the LDAP directory server.
  ///
  /// This value is initially set by the constructor and can be changed using
  /// the [setHost] method.

  String get host => _host;

  //----------------
  /// Sets the host name of the LDAP directory server.
  ///
  /// The [hostname] must be a String indicating the host name for the
  /// LDAP/LDAPS directory server.
  ///
  /// This method cannot be used to change the host name if the connection is
  /// already open. Close the connection first. A [StateError] exception will be
  /// raised if the connection is already open.
  ///
  /// If the [hostname] is null or an empty string, it defaults to "localhost".
  ///
  void setHost(String hostname) {
    if (hostname != null && hostname is! String) {
      throw new ArgumentError.value(hostname, "hostname", "not a String");
    }

    var n = (hostname != null && hostname.isNotEmpty) ? hostname : _defaultHost;

    if (n != _host) {
      if (state == ConnectionState.ready ||
          state == ConnectionState.bindRequired) {
        throw new StateError("cannot change host while connection is open");
      }
    }

    _host = n;
  }

  //----------------------------------------------------------------
  // SSL and port

  bool _isSSL = false;

  int _port = portLdap;

  //----------------
  /// Indicates the protocol being used (LDAP over SSL or plain LDAP)
  ///
  /// Value is true if LDAP over TLS/SSL is being used. Otherwise, value is
  /// false, indicating LDAP without TLS/SSL.
  ///
  /// This value is initially set by the constructor and can be changed using
  /// the [setProtocol] method.
  ///
  bool get isSSL => _isSSL;

  //----------------
  /// Port number of the LDAP directory server.
  ///
  /// This value is initially set by the constructor and can be changed using
  /// the [setProtocol] method.
  ///
  int get port => _port;

  //----------------
  /// Sets the protocol and port number of the LDAP server.
  ///
  /// If [ssl] is true, the LDAPS protocol will be used (i.e. LDAP over SSL/TLS).
  /// If [ssl] is false, the LDAP protocol is used (i.e. LDAP without SSL/TLS).
  ///
  /// If the [port] number is null, the standard port number for LDAPS or
  /// LDAP is used.
  ///
  /// This method cannot be used to change the protocol if the connection is
  /// already open. Close the connection first. A [StateError] exception will be
  /// raised if the connection is already open.
  ///
  void setProtocol(bool ssl, [int port = null]) {
    if (port != null && port is! int) {
      throw new ArgumentError.value(port, "port", "not an int");
    }

    var newSSL = (ssl == null || !ssl) ? false : true; // treat null as false
    var newPort = port;
    if (newPort == null) {
      _port = (_isSSL) ? portLdaps : portLdap; // use default
    }

    if (newSSL != _isSSL || newPort != _port) {
      // Values are being changed

      if (state == ConnectionState.ready ||
          state == ConnectionState.bindRequired) {
        throw new StateError("cannot change protocol while connection is open");
      }

      _isSSL = newSSL;
      _port = newPort;
    }
  }

  //----------------------------------------------------------------
  // Authentication credentials

  String _bindDN = ""; // desired values to use, empty string means anonymous
  String _password = "";

  /// Bind values used in most recent BIND request.
  ///
  /// In manual mode, these could be different from the desired values because
  /// [setAuthentication] has been called (or credentials set by the
  /// constructor) but [bind] has not yet been called.
  ///
  /// In automatic mode, these should always match the desired values, because
  /// the BIND request is automatically sent if it is required.

  String _sentBindDN = "";
  String _sentPassword = "";

  //----------------
  /// The distinguished name used when a BIND request is sent.
  ///
  /// If the connection is anonymous, this value is an empty string.
  ///
  /// This value is initially set by the constructor and can be changed using
  /// the [setAuthentication] method.

  String get bindDN => _bindDN;

  /*
  //----------------
  /// The password used when a BIND request is sent.
  ///
  /// If the connection is anonymous, this value is undefined.
  ///
  /// This value is initially set by the constructor and can be changed using
  /// the [setAuthentication] method.

  String get password => _password;
  */

  //----------------
  /// Sets the authentication credentials.
  ///
  /// For an authenticated connection, provide Strings for the [bindDN]
  /// and [password]. The distinguished name cannot be an empty string.
  ///
  /// For an anonymous connection, [bindDN] must be null or the empty string.
  /// The password is ignored for anonymous connections. Or use the
  /// [setAnonymous] method.
  ///
  /// If the connection is in automatic mode and is currently open, this method
  /// may send a LDAP BIND request. It is sent if one is needed, but not sent if
  /// it is not needed.
  ///
  /// If the connection is in manual mode and is currently open, a LDAP BIND
  /// request is never sent. But the state may be changed to
  /// [ConnectionState.bindRequired] and the application must then call
  /// [bind] before performing any LDAP operations. The state is not changed if
  /// it does not need to (e.g. if called with the same bindDN and password that
  /// was previously set).
  ///
  /// If the connection is not open (in either modes), the values are simply
  /// recorded for use when it is opened and/or [bind] is invoked.
  ///
  Future<LdapResult> setAuthentication(String bindDN, String password) async {
    _setAuthenticationValues(bindDN, password);

    // Send BIND request, if necessary

    var result;

    if (_autoConnect) {
      // In automatic mode. Send bind request only if necessary to make
      // the connection's bind match the authentication credentials.
      result = await _sendBind(onlyIfNecessary: true);
    } else {
      // In manual mode. Do nothing.
      // If the connection is open, the new state will either be connected or
      // bindRequired depending on the new values and what was previously sent.
      // If the connection is closed or disconnected, changing the credentials
      // does not change that.
    }

    return result;
  }

  //----------------
  /// Makes the connection anonymous.
  ///
  /// This is the same as calling [setAuthentication] with the distinguished
  /// name set to null.
  ///
  Future<LdapResult> setAnonymous() {
    return setAuthentication(null, null);
  }

  //----------------
  /// Indicates if the connection is anonymous or authenticated.
  ///
  /// Value is true if it is authenticated. Otherwise, it is false,
  /// indicating it is anonymous.
  ///
  /// This value is initially set by the constructor and can be changed using
  /// the [setAuthentication] or [setAnonymous] methods.

  bool get isAuthenticated {
    return (_bindDN.isNotEmpty);
  }

  //----------------------------------------------------------------
  // Pending completers
  //
  // These track open, automatic binding, and close operations which are
  // currently in progress.

  static List<Completer> _openCompleters = new List<Completer>();

  static List<Completer<LdapResult>> _autoBindCompleters =
      new List<Completer<LdapResult>>();

  static List<Completer> _closeCompleters = new List<Completer>();

  //================================================================
  // State

  /// Indicates the state of the LdapConnection.
  ///
  ConnectionState get state {
    if (_cmgr == null) {
      return ConnectionState.closed;
    } else {
      if (_cmgr.isClosed()) {
        return ConnectionState.disconnected;
      } else {
        if (_bindDN != _sentBindDN || _password != _sentPassword) {
          return ConnectionState.bindRequired;
        } else {
          return ConnectionState.ready;
        }
      }
    }
  }

  //================================================================
  // Constructors

  //----------------------------------------------------------------
  /// Constructor for an LDAP connection to an LDAP directory server.
  ///
  /// The connection is set to use [ssl] (or not) to connect to [port] at
  /// [hostname], and optionally authenticated to [bindDN] with [password].
  /// Automatic mode or manual mode is set according to [autoConnect].
  ///
  /// The default is to create an automatic mode, anonymous LDAP connection to
  /// localhost.
  ///
  /// These parameters can be later changed using [setHost], [setProtocol],
  /// [setAuthentication] and [setAuthentication] (see those methods for details
  /// on the values for the parameters to this constructor).
  ///
  LdapConnection(
      {String host: null,
      bool ssl: false,
      int port: null,
      String bindDN: null,
      String password: null,
      bool autoConnect: true}) {
    setHost(host);
    setProtocol(ssl, port);
    _setAuthenticationValues(bindDN, password);
    this._autoConnect = autoConnect;
  }

  //================================================================
  // Opening and authenticating

  //----------------------------------------------------------------
  /// Opens the network connection to the LDAP directory server.
  ///
  /// In automatic mode, this method will open the connection, if the connection
  /// is not already opened; and send a BIND request if one is necessary.
  /// If it is already opened, nothing is done: it is not an error to
  /// call this method on an already opened connection in automatic mode. When
  /// the Future has completed, the connection will be in the
  /// [ConnectionState.ready] state. In automatic mode, calling this
  /// method is unnecessary (since the connection will be automatically opened
  /// and authenticated when needed), but can be called.
  ///
  /// In manual mode, this method will open a closed or disconnected connection,
  /// In manual mode, a [StateError]
  /// is thrown if this method is called on an already opened connection
  /// (i.e. it is in the [ConnectionState.ready] or
  /// [ConnectionState.bindRequired] state). In manual
  /// mode, a bind request is never sent.
  /// If anonymous, after the Future completes the connection will be
  /// in the [ConnectionState.ready] state. If authenticated, after the
  /// Future completes the connection will be in the
  /// [ConnectionState.bindRequired] state and [bind] needs to be called
  /// before it can be used.
  ///
  /// In automatic mode, this method will open the connection. It will also
  /// automatically send a bind request if the connection is authenticated.
  /// The resulting connection will always be in the
  /// [ConnectionState.ready] state (for both anonymous and
  /// authenticated connections).
  ///
  /// Returns a Future which completes when the connection is ready for use.
  /// Its value is null if no LDAP BIND request was sent, or the result from the
  /// LDAP BIND request.
  ///
  /// Throws subclasses of [LdapException].
  ///
  Future<LdapResult> open() async {
    loggerConnection.fine("open: ${this.url}");

    await _requireOpen(true);

    var result = null;

    if (_autoConnect) {
      result = await _sendBind(onlyIfNecessary: true);
    }

    return result;
  }

  //----------------------------------------------------------------
  /// Closes the connection to the LDAP directory server.
  ///
  /// The connection is closed when the returned Future completes.
  ///
  /// If [immediate] is false, it waits for any/all queued operations to
  /// finish before closing the connection.
  ///
  /// If [immediate] is true, the connection is immediately closed and any
  /// queued operations are discarded.
  ///
  Future close([bool immediate = false]) async {
    loggerConnection.fine("close${immediate ? ": immediate" : ""}");

    switch (state) {
      case ConnectionState.ready:
      case ConnectionState.bindRequired:
        await _doClose(immediate);
        loggerConnection.finer("close: done");
        break;
      case ConnectionState.closed:
        loggerConnection.finer("close: was closed");
        break;
      case ConnectionState.disconnected:
        await _cmgr.close(immediate);
        loggerConnection.finer("close: was disconnected");
        break;
    }
    _cmgr = null;
  }

  Future _doClose(bool immediate) async {
    assert(_openCompleters.isEmpty);

    var c = new Completer();
    _closeCompleters.add(c);

    if (1 < _closeCompleters.length) {
      // Close in progress
      loggerConnection.finest("close in progress");
      await c.future; // wait for it to finish
      return;
    }

    try {
      loggerConnection.finest("close: started");

      await _cmgr.close(immediate);

      loggerConnection.finest("close: done");
    } catch (e) {
      rethrow;
    } finally {
      for (var cc in _closeCompleters) {
        cc.complete();
      }
      _closeCompleters.removeRange(0, _closeCompleters.length);
    }
  }

  //----------------------------------------------------------------
  /// Internal method used to set the bindDN and password member variables.
  ///
  /// It does nothing more than check the parameters (converting them to
  /// defaults if needed) and then setting those values.
  ///
  /// Throws [ArgumentError] if invalid parameters are provided.

  void _setAuthenticationValues(String bindDN, String password) {
    if (bindDN != null && bindDN is! String) {
      throw new ArgumentError.value(bindDN, "bindDN", "not a String");
    }
    if (password != null && password is! String) {
      throw new ArgumentError.value(bindDN, "password", "not a String");
    }

    if (bindDN == null || bindDN.isEmpty) {
      // Anonymous
      _bindDN = "";
      _password = "";
    } else {
      // Authenticated
      _bindDN = bindDN;
      _password = password ?? "";
    }
  }

  //----------------------------------------------------------------
  /// Internal method used when the connection needs to be opened.
  ///
  /// In automatic mode, this method will automatically open closed/disconnected
  /// connections (but not send any bind requests).
  ///
  /// In manual mode, this method opens the connection if [explicitOpen] is true
  /// and the connection is not already open. Otherwise, it throws a [StateError]
  /// since in manual mode connections are not automatically opened and it is an
  /// error to explicitly open an already opened connection.
  ///
  Future _requireOpen(bool explicitOpen) async {
    switch (state) {
      case ConnectionState.closed:
      case ConnectionState.disconnected:
        if (_autoConnect || explicitOpen) {
          if (explicitOpen) {
            loggerConnection.finer("explicit open");
          } else {
            loggerConnection.finer("automatic open: ${this.url}");
          }

          await _doOpen();
        } else {
          throw new StateError("connection is not open: ${this.url}");
        }
        break;
      case ConnectionState.bindRequired:
      case ConnectionState.ready:
        // already open
        if (!_autoConnect && explicitOpen) {
          throw new StateError("cannot open: already open: ${this.url}");
        }

        break;
    }

    // TODO: detect errors
  }

  //----------------------------------------------------------------
  /// Internal method to open connection.
  ///
  Future _doOpen() async {
    assert(_closeCompleters.isEmpty);
    assert(_autoBindCompleters.isEmpty);

    var c = new Completer();
    _openCompleters.add(c);

    if (1 < _openCompleters.length) {
      // Open already in progress
      loggerConnection.finest("open in progress");
      await c.future;
      return;
    }

    // Open not in progress
    try {
      loggerConnection.finest("opening connection: started");

      var tmp = new _ConnectionManager(_host, _port, _isSSL);

      await tmp.connect(); // might throw exception

      assert(_cmgr == null || _cmgr.isClosed());

      _cmgr = tmp;
      _sentBindDN = ""; // connection is initially anonymous
      _sentPassword = "";

      loggerConnection.finest("opening connection: done");
    } catch (e) {
      rethrow;
    } finally {
      for (var cc in _openCompleters) {
        cc.complete();
      }
      _openCompleters.removeRange(0, _openCompleters.length);
    }
  }

  //----------------------------------------------------------------
  /// Internal method used when the connection needs to be connected.
  ///
  /// In automatic mode, if the connection is closed/disconnected it will be
  /// opened (and a BIND request is sent if the connection is authenticated).
  ///
  /// In manual mode, if the connection is closed/disconnected, or a bind
  /// is required, an exception is thrown.
  ///
  /// This method is called every time before an operation is performed.
  ///
  Future _requireConnected() async {
    switch (state) {
      case ConnectionState.closed:
        if (_autoConnect) {
          await open();
        } else {
          // Manual mode: invoker was responsible for opening the connection.
          assert(_cmgr == null);
          throw new StateError("connection not open");
        }
        break;

      case ConnectionState.disconnected:
        if (_autoConnect) {
          await open();
        } else {
          // Manual mode: invoker was responsible for re-opening disconnected
          // connections. Unless they really wanted to fail in such situations,
          // they should have been using the automatic mode!
          throw new LdapConnectionDisconnected();
        }
        break;

      case ConnectionState.bindRequired:
        if (_autoConnect) {
          await _sendBind(onlyIfNecessary: true);
        } else {
          // Manual mode: invoker was responsible for sending a BIND request.
          throw new StateError("connection requires BIND");
        }
        break;

      case ConnectionState.ready:
        // already connected: nothing needs to be done
        break;
    }

    assert(state == ConnectionState.ready); // the guarantee
  }

  //----------------------------------------------------------------
  /// Internal method for sending a BIND request.
  ///
  /// The BIND request is only sent if [onlyIfNecessary] is false, or
  /// it is required so that the bind credentials are applied to the connection.
  ///
  /// This method does not examine whether the connection is in automatic mode
  /// or manual mode. It only looks at the values of the bindDN, password
  /// and [onlyIfNecessary] and whether the connection is currently open
  /// to determine whether it will send a BIND request or not.
  ///
  /// Note: this method expects the connection to be open if it needs to
  /// send a BIND request. If it does not need to send a BIND request, it
  /// does not require the connection to be open.

  Future<LdapResult> _sendBind({bool onlyIfNecessary: false}) async {
    assert(onlyIfNecessary != null);

    if (state == ConnectionState.closed ||
        state == ConnectionState.disconnected && onlyIfNecessary) {
      loggerConnection.finer("bind not required: connection not open");
      return null; // not needed, since connection is not open
    }

    // Send BIND request (if necessary) to establish the desired bind state

    if (_sentBindDN == _bindDN &&
        _sentPassword == _password &&
        onlyIfNecessary) {
      // Nothing changed and sending the bind request is optional: don't send it
      loggerConnection.finer("bind not required: no change in credentials");
      return null;
    }

    // A bind request must be sent

    assert(_cmgr != null && !_cmgr.isClosed()); // connection must be open

    if (onlyIfNecessary) {
      return await _doAutomaticBind();
    } else {
      return await _doBind();
    }
  }

  Future<LdapResult> _doAutomaticBind() async {
    loggerConnection.finer(
        "automatic bind: ${(_bindDN.isNotEmpty) ? _bindDN : "anonymous"}");

    assert(_openCompleters.isEmpty);
    assert(_closeCompleters.isEmpty);

    var c = new Completer<LdapResult>();
    _autoBindCompleters.add(c);

    if (1 < _autoBindCompleters.length) {
      // Implicit bind in progress
      return await c.future;
    }

    // Implicit bind not in progress

    var result;
    try {
      loggerConnection.finer(
          "explicit bind: ${(_bindDN.isNotEmpty) ? _bindDN : "anonymous"}");
      result = await _doBind();
      return result;
    } catch (e) {
      rethrow;
    } finally {
      for (var cc in _autoBindCompleters) {
        cc.complete(result);
      }
      _autoBindCompleters.removeRange(0, _autoBindCompleters.length);
    }
  }

  Future<LdapResult> _doBind() async {
    var r = await _cmgr.process(new BindRequest(this._bindDN, this._password));
    if (r.resultCode == ResultCode.OK) {
      loggerConnection.finer("bind: success");
      _sentBindDN = _bindDN;
      _sentPassword = _password;
    } else {
      assert(false); // exception should have been thrown if BIND failed
      return null;
    }
    return r;
  }

  //================================================================
  // LDAP operations

  //----------------------------------------------------------------
  /// Performs an LDAP BIND operation.
  ///
  /// Sends a bind request using the credentials that were set by
  /// the constructor, [setAuthentication] or [setAnonymous].
  ///
  /// This method will always sent a BIND request. It works in both manual and
  /// automatic mode. It sends a BIND request even if it is unnecessary
  /// (e.g. the connection is anonymous or the same BIND request has previously
  /// been sent).
  ///
  /// Explicitly calling this method in automatic mode is permitted, but
  /// unnecessary. Since in automatic mode a BIND request will automatically be
  /// sent if it is needed to perform an LDAP operation. It can be used to check
  /// the credentials, separately from performing an LDAP operation.
  ///
  /// Returns a Future containing the result of the BIND operation.
  ///
  Future<LdapResult> bind() async {
    loggerConnection.fine("bind: ${_bindDN.isEmpty ? "anonymous" : _bindDN}");

    await _requireOpen(false); // exception if not open and in manual mode

    return await _sendBind(onlyIfNecessary: false); // always send bind
  }

  //----------------------------------------------------------------
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
  ///     var sr = await connection.search(base, filter, attrs);
  ///     await for (var entry in sr.stream) {
  ///       // process the entry (SearchEntry)
  ///       // entry.dn = distinguished name (String)
  ///       // entry.attributes = attributes returned (Map<String,Attribute>)
  ///     }

  Future<SearchResult> search(
      String baseDN, Filter filter, List<String> attributes,
      {int scope: SearchScope.SUB_LEVEL,
      int sizeLimit: 0,
      List<Control> controls: null}) async {
    loggerConnection.fine("search");

    await _requireConnected();
    return _cmgr.processSearch(
        new SearchRequest(baseDN, filter, attributes, scope, sizeLimit),
        controls);
  }

  //----------------------------------------------------------------
  /// Performs an LDAP add operation.
  ///
  /// [dn] is the LDAP Distinguised Name.
  /// [attrs] is a map of attributes keyed by the attribute name. The
  ///  attribute values can be simple Strings, lists of strings,
  ///or alternatively can be of type [Attribute]
  ///
  Future<LdapResult> add(String dn, Map<String, dynamic> attrs) async {
    loggerConnection.fine("add: $dn");
    await _requireConnected();
    return await _cmgr
        .process(new AddRequest(dn, Attribute.newAttributeMap(attrs)));
  }

  //----------------------------------------------------------------
  /// Performs an LDAP delete operation.
  ///
  /// Delete the LDAP entry identified by the distinguished name in [dn].
  ///
  Future<LdapResult> delete(String dn) async {
    loggerConnection.fine("delete: $dn");
    await _requireConnected();
    return await _cmgr.process(new DeleteRequest(dn));
  }

  //----------------------------------------------------------------
  /// Performs an LDAP modify operation.
  ///
  /// Modifies the LDAP entry [dn] with the list of modifications [mods].
  ///
  Future<LdapResult> modify(String dn, Iterable<Modification> mods) async {
    loggerConnection.fine("modify");
    await _requireConnected();
    return await _cmgr.process(new ModifyRequest(dn, mods));
  }

  //----------------------------------------------------------------
  /// Performs an LDAP modifyDN operation.
  ///
  /// Modify the LDAP entry identified by [dn] to a new relative [rdn].
  /// If [deleteOldRDN] is true delete the old entry.
  /// If [newSuperior] is not null, re-parent the entry.
  ///
  // todo: consider making optional args as named args
  Future<LdapResult> modifyDN(String dn, String rdn,
      [bool deleteOldRDN = true, String newSuperior]) async {
    loggerConnection.fine("modifyDN");
    await _requireConnected();
    return await _cmgr
        .process(new ModDNRequest(dn, rdn, deleteOldRDN, newSuperior));
  }

  //----------------------------------------------------------------
  /// Performs an LDAP compare operation.
  ///
  /// On the LDAP entry identifyed by the distinguished name [dn],
  /// compare the [attrName] and [attrValue] to see if they are the same.
  ///
  /// The completed [LdapResult] will have a value of [ResultCode.COMPARE_TRUE]
  /// or [ResultCode.COMPARE_FALSE].
  ///
  Future<LdapResult> compare(
      String dn, String attrName, String attrValue) async {
    loggerConnection.fine("compare");
    await _requireConnected();
    return await _cmgr.process(new CompareRequest(dn, attrName, attrValue));
  }

  //================================================================

  /// URL representation of the LDAP connection's host and port.
  ///
  /// For example, "ldap://example.com" or "ldaps://example.com:10636".
  ///
  String get url {
    if (_isSSL) {
      return "ldaps://" + _host + (_port != portLdaps ? ":$_port" : "");
    } else {
      return "ldap://" + _host + (_port != portLdap ? ":$_port" : "");
    }
  }
}

//================================================================

/// States for an [LdapConnection].
///
/// The [LdapConnection.state] method returns one of these values:
///
/// - closed
/// - ready
/// - bindRequired
/// - disconnected
///
/// ## closed
///
/// The connection has never been opened (explicitly or automatically), or was
/// previously opened but has since been explicitly closed by calling
/// [LdapConnection.close].  This is the initial state of a newly created LDAP
/// connection.
///
/// ## ready
///
/// The connection is open (explicitly or automatically) and any necessary LDAP
/// binding has also been established.
///
/// ## bindRequired
///
/// This state may only occurs in manual mode. It indicates the connection has
/// been opened, but the necessary LDAP binding has not been established.
///
/// In manual mode, the application is responsible for explicitly sending any
/// LDAP BIND requests. If the connection is anonymous, calling
/// [LdapConnection.open] will make a _closed_ connection _ready_. If the
/// connection is authenticated, calling [LdapConnection.open] will make a
/// _closed_ connection _bindRequired_. A _ready_ connection will drop back to
/// the _bindRequired_ state if the LDAP binding is changed (e.g. changing the
/// bindDN, making an authenticated connection anonymous or vice versa).  In
/// either case, calling [LdapConnection.bind] will then make a _bindRequired_
/// connection to _ready_.
///
/// In automatic mode, calling [LdapConnection.open] (or simply performing an
/// LDAP operation) will automatically bind the authenticated connections. So
/// this state is skipped and the connection becomes _connected_.
///
/// ## disconnected
///
/// The connection is disconnected. It was previously (explicitly or
/// automatically) opened, but has since been disconnected and not explicitly
/// closed or (explicitly or automatically) re-opened.
///
/// Disconnections are outside the control of the application, and could occur
/// at anytime (except, of course, if the connection is already closed). For
/// example, they can occur if the LDAP server timesout the connection, the LDAP
/// server is shut down, or the network is disconnected.

enum ConnectionState {
  /// Connection is not open.
  ///
  closed,

  /// Connection is open, but any necessary LDAP binding has not been established.
  ///
  bindRequired,

  /// Connection is open and any necessary LDAP binding established.
  ///
  ready,

  /// Connection should be open, but is not.
  ///
  disconnected
}
