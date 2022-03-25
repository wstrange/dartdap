import 'dart:io';
import 'dart:async';

import 'package:dartdap/dartdap.dart';

import '../protocol/ldap_protocol.dart';
import 'connection_info.dart';

/// Connection to perform LDAP operations on an LDAP server.
///
/// ## Properties
///
/// An LdapConnection is defined by the network connection and the LDAP binding.
///
/// The network connection is determined by the hostname, whether SSL/TLS is
/// used or not, and the port number.
///
///
/// The [badCertHandler] is a callback function to process bad certificates
/// (if encountered when attempting to establish a TLS/SSL connection).
/// The callback function should return true to accept the certificate (and
/// the security consequences of doing so), or false to reject it. If no
/// certificate callback is provided, the default behaviour is to throw
/// the [LdapCertificateException] if a bad certificate is encountered.
///
/// ## Connection management
///
/// ### State
///
/// The state of the LdapConnection can be determined by examining its [state].
///
///
/// ### Disconnections
///
/// An open network connection can be disconnected by external causes, which are
/// outside the control of the application.  For example, disconnections occur
/// when: the LDAP server times out the connection, the LDAP server is
/// re-started, or network errors causes the connection to be dropped.
/// See the [LdapConnectionPool] to handle dropped connections. etc.
///
///
///
/// ### Results
///
/// All of the above LDAP operation methods return a [Future] to an [LdapResult].
///
/// The [LdapResult] contains a _resultCode_ value that will always be either
/// [ResultCode.OK], [ResultCode.COMPARE_FALSE] or [ResultCode.COMPARE_TRUE].
/// The last two values only occur when performing a _compare_ operation.  For
/// all other operations, the _resultCode_ does not carry useful information,
/// because errors will cause an exception to be thrown.
///
/// ### Exceptions
///
/// This package defines exceptions that are all subclasses of the abstract
/// [LdapResultException] class.
///
/// In automatic mode, all of them can also throw any of the exceptions the
/// [open] or [bind] methods can throw.
///
/// In manual mode, all of them can also throw [StateError] if the connection
/// is _closed_ or _disconnected_. Also, all of them except [bind] can also
/// throw [StateError] if it is in manual mode and the state is _bindRequired_.
///
/// All of the above LDAP operation methods can also thrown exceptions specific
/// to their operation. See the documentation of specific methods for some
/// of these, or the classes that implement the [LdapException]. The
/// abstract [LdapResultException] is an abstract class that is a base class
/// of exceptions relating to the result of LDAP operations.
///
/// Standard
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

class LdapConnection extends Ldap {
  //================================================================
  // Members

  ///
  /// The underlying connection manager.
  ///
  late ConnectionManager _cmgr;

  // the last bind request made on this connection
  BindRequest? _lastBindRequest;

  //----------------------------------------------------------------
  // Hostname
  final String _host;

  //----------------
  /// Host name of the LDAP directory server.
  ///
  /// This value is initially set by the constructor
  String get host => _host;

  //----------------------------------------------------------------
  // SSL, port and Context (for certificates)

  final bool _isSSL;

  // ldap port
  final int _port;

  SecurityContext? _context;

  //----------------
  /// Indicates the protocol being used (LDAP over SSL or plain LDAP)
  ///
  /// Value is true if LDAP over TLS/SSL is being used. Otherwise, value is
  /// false, indicating LDAP without TLS/SSL.
  ///
  bool get isSSL => _isSSL;

  //----------------
  /// Port number of the LDAP directory server.
  ///
  int get port => _port;

  //----------------------------------------------------------------
  // Certificate handling

  /// Callback handler for bad certificates encountered when establishing a
  /// SSL/TLS connection. This method should return true if the program wants
  /// to accept the certificate anyway (accepting the security risks involved);
  /// or return false to reject the certificate (and not establish a
  /// connection).
  ///
  /// If this is null, the default behaviour is to throw an
  /// [LdapCertificateException] if a bad certificate is encountered.
  ///
  final BadCertHandlerType _badCertHandler;
  BadCertHandlerType get badCertHandler => _badCertHandler;

  //----------------------------------------------------------------
  // Authentication credentials

  // Note: bindDN and passwords are ALWAYS Strings (possibly empty strings).
  // These internal members are never null (even though the externally visible
  // methods accept null as valid parameters).

  String _bindDN = ''; // desired values to use, empty string means anonymous
  String _password = '';

  //----------------
  /// The distinguished name used when a BIND request is sent.
  ///
  /// If the connection is anonymous, this value is an empty string.
  ///
  /// This value is initially set by the constructor but rebinding
  /// with a new DN can change this value
  String get bindDN => _bindDN;

  // Information on the connection. Time created, etc.
  ConnectionInfo connectionInfo = ConnectionInfo();

  //================================================================
  // State
  ConnectionState state = ConnectionState.closed;

  // Counter for incrementing the connection id
  static int _nextConnectionId = 0;
  // Unique Id for this connection
  final int _connectionId = _nextConnectionId++;

  /// Return the unique connection id for this connection
  /// TODO: How does this work with isolates?
  int get connectionId => _connectionId;

  //================================================================
  // Constructors

  //----------------------------------------------------------------
  /// Constructor for an LDAP connection to an LDAP directory server.
  ///
  /// The connection is set to use [ssl] (or not) to connect to [port] at
  /// [host], and optionally authenticated to [bindDN] with [password].
  ///
  ///
  ///
  /// The [badCertHandler] is set to [badCertificateHandler]. If null,
  /// a [LdapCertificateException] is thrown if the certificate is bad.
  ///
  /// ## Exceptions
  ///
  /// - [ArgumentError] when parameters are incorrect:
  ///   host, bindDN or password is not a String or null; or
  ///   port is not an int or null.
  /// - [StateError] when the connection is currently open and the host, port,
  ///   or ssl is changed. Close the connection before making changes.
  ///
  LdapConnection(
      {String host = 'localhost',
      bool ssl = false,
      int port = Ldap.PORT_LDAP,
      String bindDN = '',
      String password = '',
      BadCertHandlerType badCertificateHandler = defaultBadCertHandler,
      SecurityContext? context})
      : _host = host,
        _port = port,
        _bindDN = bindDN,
        _password = password,
        _isSSL = ssl,
        _badCertHandler = badCertificateHandler {
    _cmgr = ConnectionManager(this, tlsSecurityContext: _context);
  }

  // Create a new [LdapConnection] by copying the parameters of
  // the LdapConnection c
  LdapConnection.copy(LdapConnection c)
      : _host = c.host,
        _port = c.port,
        _bindDN = c.bindDN,
        _password = c._password,
        _isSSL = c._isSSL,
        _lastBindRequest = c._lastBindRequest,
        _badCertHandler = c._badCertHandler {
    _cmgr = ConnectionManager(this, tlsSecurityContext: _context);
  }

  //================================================================
  // Opening and authenticating

  //----------------------------------------------------------------
  /// Opens the network connection to the LDAP directory server.
  ///
  ///
  /// Returns a Future which completes when the connection is ready for use.
  /// Throws subclasses of [LdapException].
  ///
  ///   /// ## Exceptions
  ///
  /// - [LdapSocketException] when an error with the underlying socket.
  /// - [LdapSocketServerNotFoundException] when the server cannot
  ///   be found. Check the hostname is correct.
  /// - [LdapSocketRefusedException] when the port on the server
  ///   cannot be connected to. Check LDAP is running on the server
  ///   and the port number is correct.
  /// - [StateError] if the connection is already
  ///   opened (i.e. it can't be re-opened without first closing it).
  /// - Other exceptions might also be thrown.
  ///
  ///
  Future<void> open() async {
    loggerConnection.fine('open: $url');
    switch (state) {
      case ConnectionState.closed:
        await _cmgr.connect();
        state = ConnectionState.ready;
        return;
      default:
        throw StateError('Attempt to open connection that is already opened');
    }
  }

  ///
  /// Reopen the connection, and rebind with the last known bind credentiuals
  ///
  Future<void> reconnect() async {
    loggerConnection.fine('reconnecting');
    // force close of socket..
    await close();
    await open();
    if (_lastBindRequest != null) {
      await _doBind(_lastBindRequest!);
    }
  }

  //----------------------------------------------------------------
  /// Closes the connection to the LDAP directory server.
  ///
  /// The connection is closed when the returned Future completes.
  ///
  ///
  Future<void> close() async {
    loggerConnection.fine('close');

    switch (state) {
      case ConnectionState.ready:
      case ConnectionState.bound:
        await _cmgr.close();
        loggerConnection.finer('close: done');
        state = ConnectionState.closed;
        break;
      case ConnectionState.closed:
        loggerConnection.finer('close: was closed');
        break;
      case ConnectionState.error:
        await _cmgr.close();
        state = ConnectionState.closed;
        loggerConnection.finer('close: was disconnected');
        break;
    }
  }

  //================================================================
  // LDAP operation implementation

  @override
  Future<LdapResult> bind({String? DN, String? password}) async {
    loggerConnection.fine('bind: ${_bindDN.isEmpty ? 'anonymous' : _bindDN}');

    _bindDN = DN ?? _bindDN;
    _password = password ?? _password;

    return _doBind(BindRequest(_bindDN, _password));
  }

  Future<LdapResult> _doBind(BindRequest bindRequest) async {
    var r = await _cmgr.process(bindRequest);
    if (r.resultCode == ResultCode.OK) {
      loggerConnection.finer('bind: success');
      state = ConnectionState.bound;
      _lastBindRequest = bindRequest;
    }
    return r;
  }

  @override
  Future<SearchResult> search(
      String baseDN, Filter filter, List<String> attributes,
      {int scope = SearchScope.SUB_LEVEL,
      int sizeLimit = 0,
      List<Control> controls = const <Control>[]}) async {
    loggerConnection.fine('search');

    return _cmgr.processSearch(
        SearchRequest(baseDN, filter, attributes, scope, sizeLimit), controls);
  }

  @override
  Future<LdapResult> add(String dn, Map<String, dynamic> attrs) async {
    loggerConnection.fine('add: $dn');
    return await _cmgr
        .process(AddRequest(dn, Attribute.newAttributeMap(attrs)));
  }

  @override
  Future<LdapResult> delete(String dn) async {
    loggerConnection.fine('delete: $dn');
    return await _cmgr.process(DeleteRequest(dn));
  }

  @override
  Future<LdapResult> modify(String dn, List<Modification> mods) async {
    loggerConnection.fine('modify');
    return await _cmgr.process(ModifyRequest(dn, mods));
  }

  @override
  Future<LdapResult> modifyDN(String dn, String rdn,
      {bool deleteOldRDN = true, String? newSuperior}) async {
    loggerConnection.fine('modifyDN');
    return await _cmgr
        .process(ModDNRequest(dn, rdn, deleteOldRDN, newSuperior));
  }

  @override
  Future<LdapResult> compare(
      String dn, String attrName, String attrValue) async {
    loggerConnection.fine('compare');
    return await _cmgr.process(CompareRequest(dn, attrName, attrValue));
  }

  // Abandon the request specified by messageId
  // This is not a future because the server is not expected to reply.
  // An Abandon of message Id=0 can be used to keep an ldap connection alive.
  // See https://stackoverflow.com/questions/313575/ldap-socket-keep-alive
  void abandonRequest({required int messageId}) {
    _cmgr.sendLdapBytes(LDAPMessage(messageId, AbandonRequest(messageId)));
  }
  //================================================================

  //----------------------------------------------------------------
  /// Default bad certificate handler.
  ///
  /// Used to handle bad certificates, if no custom handler is provided.
  ///
  static bool defaultBadCertHandler(X509Certificate cert) {
    throw LdapCertificateException(cert);
    // normally, method should return false to reject it
  }

  //================================================================

  /// URL representation of the LDAP connection's host and port.
  ///
  /// For example, 'ldap://example.com' or 'ldaps://example.com:10636'.
  ///
  String get url {
    var proto = isSSL ? 'ldaps' : 'ldap';
    return '$proto://$_host:$_port';
  }

  bool get isBound => state == ConnectionState.bound;

  bool get isReady => state == ConnectionState.ready || isBound;

  @override
  String toString() =>
      'LdapConnection($_host:$_port id=$_connectionId, state=$state)';
}

//================================================================

/// States for an [LdapConnection].
enum ConnectionState {
  /// Connection is not open.
  closed,

  /// Connection is open and ready for LDAP requests
  /// Note that a bind is not strictly required if anonymous searches
  /// are allowed by the server
  ready,

  /// Connection is open, ready for requests, and has BINDed with credentials
  bound,

  /// Connection is in an error state
  error
}
