part of dartdap;

/**
 * Holds a pending LDAP operation that we have issued to the server. We
 * expect to get a response back from the server for this op. We match
 * the response against the message Id. example: We send request with id = 1234,
 * we expect a response with id = 1234
 *
 * todo: Implement timeouts?
 */
abstract class _PendingOp {
  Stopwatch _stopwatch = new Stopwatch()..start();

  // the message we are waiting for a response from
  LDAPMessage message;

  _PendingOp(this.message);

  String toString() => "PendingOp m=${message}";

  // Process an LDAP result. Return true if this operation is now complete
  bool processResult(ResponseOp op);

  done() {
    var ms = _stopwatch.elapsedMilliseconds;
    loggerSendLdap.fine("LDAP request serviced: $message ($ms ms)");
  }
}

// A pending operation that has multiple values returned via a
// Stream. Used for SearchResults.
class _StreamPendingOp extends _PendingOp {
  StreamController<SearchEntry> _controller =
      new StreamController<SearchEntry>();
  SearchResult _searchResult;
  SearchResult get searchResult => _searchResult;

  _StreamPendingOp(LDAPMessage m) : super(m) {
    _searchResult = new SearchResult(_controller.stream);
  }

  // process the stream op - return false if we expect more data to come
  // or true if the search is complete
  bool processResult(ResponseOp op) {
    // op is Search Entry. Add it to our stream and keep
    if (op is SearchResultEntry) {
      _controller.add(op.searchEntry);
      return false;
    } else {
      // we should be done now
      // if this is not a done message we are in trouble...
      var x = (op as SearchResultDone);

      if (x.ldapResult.resultCode != 0) _controller.addError(x.ldapResult);

      _searchResult.controls = x.controls;
      _searchResult.ldapResult = x.ldapResult;
      _controller.close();
      done();
    }
    return true; // op complete
  }
}

// A pending opertion that expects a single return response message
// returned via a future. For all LDAP ops except search results
class _FuturePendingOp extends _PendingOp {
  var completer = new Completer();

  _FuturePendingOp(LDAPMessage m) : super(m);

  bool processResult(ResponseOp op) {
    var ldapResult = op.ldapResult;

    if (ldapResult.resultCode == ResultCode.OK ||
        ldapResult.resultCode == ResultCode.COMPARE_FALSE ||
        ldapResult.resultCode == ResultCode.COMPARE_TRUE) {
      // These are not treated as errors. Let the result code propagate back.
      completer.complete(ldapResult);
    } else {
      // Everything else is treated as an error

      var e;

      switch (ldapResult.resultCode) {
        case ResultCode.OPERATIONS_ERROR:
          e = new LdapResultOperationsErrorException(ldapResult);
          break;

        case ResultCode.PROTOCOL_ERROR:
          e = new LdapResultProtocolErrorException(ldapResult);
          break;

        case ResultCode.TIME_LIMIT_EXCEEDED:
          e = new LdapResultTimeLimitExceededException(ldapResult);
          break;

        case ResultCode.SIZE_LIMIT_EXCEEDED:
          e = new LdapResultSizeLimitExceededException(ldapResult);
          break;

        case ResultCode.AUTH_METHOD_NOT_SUPPORTED:
          e = new LdapResultAuthMethodNotSupportedException(ldapResult);
          break;

        case ResultCode.STRONG_AUTH_REQUIRED:
          e = new LdapResultStrongAuthRequiredException(ldapResult);
          break;

        case ResultCode.REFERRAL:
          e = new LdapResultReferralException(ldapResult);
          break;

        case ResultCode.ADMIN_LIMIT_EXCEEDED:
          e = new LdapResultAdminLimitExceededException(ldapResult);
          break;

        case ResultCode.UNAVAILABLE_CRITICAL_EXTENSION:
          e = new LdapResultUnavailableCriticalExtensionException(ldapResult);
          break;

        case ResultCode.CONFIDENTIALITY_REQUIRED:
          e = new LdapResultConfidentialityRequiredException(ldapResult);
          break;

        case ResultCode.SASL_BIND_IN_PROGRESS:
          e = new LdapResultSaslBindInProgressException(ldapResult);
          break;

        case ResultCode.NO_SUCH_ATTRIBUTE:
          e = new LdapResultNoSuchAttributeException(ldapResult);
          break;

        case ResultCode.UNDEFINED_ATTRIBUTE_TYPE:
          e = new LdapResultUndefinedAttributeTypeException(ldapResult);
          break;

        case ResultCode.INAPPROPRIATE_MATCHING:
          e = new LdapResultInappropriateMatchingException(ldapResult);
          break;

        case ResultCode.CONSTRAINT_VIOLATION:
          e = new LdapResultConstraintViolationException(ldapResult);
          break;

        case ResultCode.ATTRIBUTE_OR_VALUE_EXISTS:
          e = new LdapResultAttributeOrValueExistsException(ldapResult);
          break;

        case ResultCode.INVALID_ATTRIBUTE_SYNTAX:
          e = new LdapResultInvalidAttributeSyntaxException(ldapResult);
          break;

        case ResultCode.NO_SUCH_OBJECT:
          e = new LdapResultNoSuchObjectException(ldapResult);
          break;

        case ResultCode.ALIAS_PROBLEM:
          e = new LdapResultAliasProblemException(ldapResult);
          break;

        case ResultCode.INVALID_DN_SYNTAX:
          e = new LdapResultInvalidDnSyntaxException(ldapResult);
          break;

        case ResultCode.IS_LEAF:
          e = new LdapResultIsLeafException(ldapResult);
          break;

        case ResultCode.ALIAS_DEREFERENCING_PROBLEM:
          e = new LdapResultAliasDereferencingProblemException(ldapResult);
          break;

        case ResultCode.INAPPROPRIATE_AUTHENTICATION:
          e = new LdapResultInappropriateAuthenticationException(ldapResult);
          break;

        case ResultCode.INVALID_CREDENTIALS:
          e = new LdapResultInvalidCredentialsException(ldapResult);
          break;

        case ResultCode.INSUFFICIENT_ACCESS_RIGHTS:
          e = new LdapResultInsufficientAccessRightsException(ldapResult);
          break;

        case ResultCode.BUSY:
          e = new LdapResultBusyException(ldapResult);
          break;

        case ResultCode.UNAVAILABLE:
          e = new LdapResultUnavailableException(ldapResult);
          break;

        case ResultCode.UNWILLING_TO_PERFORM:
          e = new LdapResultUnwillingToPerformException(ldapResult);
          break;

        case ResultCode.LOOP_DETECT:
          e = new LdapResultLoopDetectException(ldapResult);
          break;

        case ResultCode.NAMING_VIOLATION:
          e = new LdapResultNamingViolationException(ldapResult);
          break;

        case ResultCode.OBJECT_CLASS_VIOLATION:
          e = new LdapResultObjectClassViolationException(ldapResult);
          break;

        case ResultCode.NOT_ALLOWED_ON_NONLEAF:
          e = new LdapResultNotAllowedOnNonleafException(ldapResult);
          break;

        case ResultCode.NOT_ALLOWED_ON_RDN:
          e = new LdapResultNotAllowedOnRdnException(ldapResult);
          break;

        case ResultCode.ENTRY_ALREADY_EXISTS:
          e = new LdapResultEntryAlreadyExistsException(ldapResult);
          break;

        case ResultCode.OBJECT_CLASS_MODS_PROHIBITED:
          e = new LdapResultObjectClassModsProhibitedException(ldapResult);
          break;

        case ResultCode.AFFECTS_MULTIPLE_DSAS:
          e = new LdapResultAffectsMultipleDsasException(ldapResult);
          break;

        case ResultCode.OTHER:
          e = new LdapResultOtherException(ldapResult);
          break;

        default:
          assert(ldapResult.resultCode != ResultCode.OK);
          assert(ldapResult.resultCode != ResultCode.COMPARE_FALSE);
          assert(ldapResult.resultCode != ResultCode.COMPARE_TRUE);
          e = new LdapResultUnknownCodeException(ldapResult);
          break;
      }
      completer.completeError(e);
    }

    done();
    return true;
  }
}

/**
 * Manages the state of the LDAP connection.
 *
 * Queues LDAP operations and sends them to the LDAP server.
 */

class ConnectionManager {
  // Queue for all outbound messages.
  Queue<_PendingOp> _outgoingMessageQueue = new Queue<_PendingOp>();

  // Messages that we are expecting a response back from the LDAP server
  Map<int, _PendingOp> _pendingResponseMessages = new Map();

  // TIMEOUT when waiting for a pending op to come back from the server.
  static const PENDING_OP_TIMEOUT = const Duration(seconds: 3);
  //
  bool _bindPending = false; // true if a BIND is pending
  Socket _socket;

  // true if this connection is closed
  // (if the socket is null, we consider it closed)
  bool isClosed() => _socket == null;

  int _nextMessageId = 1; // message counter for this connection

  int _port;
  String _host;
  bool _ssl;

  ConnectionManager(this._host, this._port, this._ssl);

  /// Establishes a network connection to the LDAP server.
  ///
  /// Throws a [LdapSocketException] if a socket exception occurs.
  /// Two particular socket exceptions are detected.
  /// Throws a [LdapSocketServerNotFoundException] if the server cannot
  /// be found.
  /// Throws a [LdapSocketRefusedException] if the port on the server
  /// cannot be connected to.

  Future<ConnectionManager> connect() async {
    loggerConnection
        .finer("Opening ${_ssl ? "secure " : ""}socket to ${_host}:${_port}");

    try {
      var s = (_ssl
          ? SecureSocket.connect(_host, _port,
              onBadCertificate: _badCertHandler)
          : Socket.connect(_host, _port));

      _socket = await s;

      _socket
          .transform(_createLdapTransformer())
          .listen((m) => _handleLDAPMessage(m), onError: (error, stacktrace) {
        loggerConnection.finer("Socket error", error, stacktrace);
        if (error is SocketException) {
          throw new LdapSocketException(error);
        } else {
          throw error;
        }
      });
    } on SocketException catch (e) {
      if (e.osError != null) {
        if (e.osError.errorCode == 61) {
          // errorCode 61 = "Connection refused"
          throw new LdapSocketRefusedException(e, _host, _port);
        } else if (e.osError.errorCode == 8) {
          // errorCode 8 = "nodename nor servname provided, or not known"
          throw new LdapSocketServerNotFoundException(e, _host);
        }
      }
      rethrow;
    }

    loggerConnection
        .fine("Opened ${_ssl ? "secure " : ""}socket to $_host:$_port");

    return this;
  }

  // Called when the SSL cert is not valid
  // Return true to carry on anyways. TODO: Make it configurable
  bool _badCertHandler(X509Certificate cert) {
    loggerConnection.warning(
        "Invalid Certificate: issuer=${cert.issuer} subject=${cert.subject}");
    loggerConnection
        .warning("SSL Connection will proceed. Please fix the certificate");
    return true; // carry on
  }

  // process an LDAP Search Request
  SearchResult processSearch(SearchRequest rop, List<Control> controls) {
    var m = new LDAPMessage(++_nextMessageId, rop, controls);
    var op = new _StreamPendingOp(m);
    _queueOp(op);
    return op.searchResult;
  }

  // Process a generic LDAP operation.
  Future<LDAPResult> process(RequestOp rop) {
    var m = new LDAPMessage(++_nextMessageId, rop);
    var op = new _FuturePendingOp(m);
    _queueOp(op);
    return op.completer.future;
  }

  _queueOp(_PendingOp op) {
    _outgoingMessageQueue.add(op);
    _sendPendingMessage();
  }

  _sendPendingMessage() {
    //logger.finest("Send pending message()");
    while (_messagesToSend()) {
      var op = _outgoingMessageQueue.removeFirst();
      _sendMessage(op);
    }
  }

  /**
   * Return TRUE if there are messages waiting to be sent.
   *
   * Note that BIND is synchronous (as per LDAP spec) - so if there is a pending BIND
   * we must wait to send more messages until the BIND response comes back from the
   * server
   */
  bool _messagesToSend() =>
      (!_outgoingMessageQueue.isEmpty) && (_bindPending == false);

  // Send a single message to the server
  _sendMessage(_PendingOp op) {
    loggerSendLdap.fine("Send LDAP message: ${op.message}");
    var l = op.message.toBytes();
    _socket.add(l);
    _pendingResponseMessages[op.message.messageId] = op;
    if (op.message.protocolTag == BIND_REQUEST) _bindPending = true;
  }

  /**
   *
   *
   * Close the LDAP connection.
   *
   * Pending operations will be allowed to finish, unless immediate = true
   *
   * Returns a Future that is called when the connection is closed
   */

  Future close(bool immediate) {
    if (immediate || _canClose()) {
      return _doClose();
    } else {
      var c = new Completer();
      // todo: dont wait if there are no pending ops....
      new Timer.periodic(PENDING_OP_TIMEOUT, (Timer t) {
        if (_canClose()) {
          t.cancel();
          _doClose().then((_) => c.complete());
        }
      });
      return c.future;
    }
  }

  /**
   * Return true if there are no more pending messages.
   */
  bool _canClose() {
    if (_pendingResponseMessages.isEmpty && _outgoingMessageQueue.isEmpty) {
      return true;
    }
    loggerConnection.finer(
        "close() waiting for queue to drain pendingResponse=$_pendingResponseMessages");
    _sendPendingMessage();
    return false;
  }

  Future _doClose() {
    loggerConnection.fine("Closing socket");
    var f = (_socket != null) ? _socket.close() : null;
    _socket = null;
    return f;
  }

  /// Processes received LDAP messages.
  ///
  /// This method handles the LDAP messages which have been parsed from the
  /// bytes read from the socket. It is invoked from the bytes-to-LDAPMessage
  /// transformer on the socket.

  void _handleLDAPMessage(LDAPMessage m) {
    // call response handler to figure out what kind of resposnse
    // the message contains.
    var rop = ResponseHandler.handleResponse(m);
    // match it to a pending operation based on message id
    // todo: AN extended protocol op may not match an outstanding request
    // hanndle this case

    if (rop is ExtendedResponse) {
      var o = rop as ExtendedResponse;
      loggeRecvLdap.fine(
          "Got extended response ${o.responseName} code=${rop.ldapResult.resultCode}");
    }

    var pending_op = _pendingResponseMessages[m.messageId];

    // If this is not true, the server sent us possibly
    // malformed LDAP. What should we do?? Not clear if
    // we should throw an exception or try to ignore the error bytes
    // and carry on....
    if (pending_op == null)
      throw new LdapParseException(
          "Server sent us an unknown message id = ${m.messageId} opCode=${m.protocolTag}");

    if (pending_op.processResult(rop)) {
      // op is now complete. Remove it from pending q
      _pendingResponseMessages.remove(m.messageId);
    }

    if (m.protocolTag == BIND_RESPONSE) _bindPending = false;
  }
}
