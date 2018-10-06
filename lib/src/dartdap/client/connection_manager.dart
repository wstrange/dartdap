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

//================================================================

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
    } else if (op is SearchResultDone) {
      // we should be done now
      // if this is not a done message we are in trouble...

      if (op.ldapResult.resultCode != ResultCode.OK) {
        // Error result: convert to an exception class and add to controller
        _controller.addError(op.ldapResult.exceptionFromResultCode());
      }

      _searchResult.controls = op.controls;
      _searchResult.ldapResult = op.ldapResult;
      _controller.close();
      done();
    } else {
      // This is unexpected
      assert(false);
      _controller.addError(new LdapResultUnknownCodeException(null));
      _controller.close(); // TODO: Is the correct way to handle this?
      done();
    }
    return true; // op complete
  }
}

//================================================================

// A pending opertion that expects a single return response message
// returned via a future. For all LDAP ops except search results
class _FuturePendingOp extends _PendingOp {
  var completer = Completer<LdapResult>();

  _FuturePendingOp(LDAPMessage m) : super(m);

  bool processResult(ResponseOp op) {
    var ldapResult = op.ldapResult;

    if (ldapResult.resultCode == ResultCode.OK ||
        ldapResult.resultCode == ResultCode.COMPARE_FALSE ||
        ldapResult.resultCode == ResultCode.COMPARE_TRUE) {
      // These are not treated as errors. Let the result code propagate back.
      completer.complete(ldapResult);
    } else {
      // Everything else is treated as an error: convert to an exception
      completer.completeError(ldapResult.exceptionFromResultCode());
    }

    done();
    return true;
  }
}

//================================================================

/// Callback function type for handling bad certificates.
///
/// The function should return true to accept the certificate
/// (and the security consequences of doing so) or false to
/// reject it (and not establish the SSL/TLS connection).

typedef bool BadCertHandlerType(X509Certificate cert);

//================================================================

/**
 * Manages the state of the LDAP connection.
 *
 * Queues LDAP operations and sends them to the LDAP server.
 */

class _ConnectionManager {
  // Queue for all outbound messages.
  Queue<_PendingOp> _outgoingMessageQueue = new Queue<_PendingOp>();

  // Messages that we are expecting a response back from the LDAP server
  Map<int, _PendingOp> _pendingResponseMessages = new Map();

  // TIMEOUT when waiting for a pending op to come back from the server.
  static const PENDING_OP_TIMEOUT = const Duration(seconds: 3);
  //
  bool _bindPending = false; // true if a BIND is pending
  Socket _socket;

  //----------------------------------------------------------------
  /// Indicates if the connection is closed.
  ///
  /// Returns true if the connection is closed, false otherwise.

  // (if the socket is null, we consider it closed)
  bool isClosed() => _socket == null;

  int _nextMessageId = 1; // message counter for this connection

  int _port;
  String _host;
  bool _ssl;
  SecurityContext _context;

  BadCertHandlerType _badCertHandler = null;

  /// Completes when the stream transformer is done.
  /// Indicates the connection is completely closed.
  ///
  Completer _whenDone;

  //----------------------------------------------------------------
  /// Constructor
  ///
  /// Creates and initializes a connection object.
  ///
  /// The actual TCP/IP connection is not established.
  ///

  _ConnectionManager(this._host, this._port, this._ssl, this._badCertHandler,
      [this._context]);

  //================================================================
  // Connecting

  //----------------------------------------------------------------
  /// Establishes a network connection to the LDAP server.
  ///
  /// ## Exceptions
  ///
  /// - [LdapSocketException] when an error with the underlying socket.
  /// - [LdapSocketServerNotFoundException] when the server cannot
  ///   be found. Check the hostname is correct.
  /// - [LdapSocketRefusedException] when the port on the server
  ///   cannot be connected to. Check LDAP is running on the server
  ///   and the port number is correct.
  /// - Other exceptions might also be thrown.

  Future<_ConnectionManager> connect() async {
    try {
      if (isClosed()) {
        var s = (_ssl)
            ? SecureSocket.connect(_host, _port,
                onBadCertificate: _badCertHandler, context: _context)
            : Socket.connect(_host, _port);

        _socket = await s;

        _whenDone = new Completer();

        // FIXME: I think the .cast causes bad performance...
        // https://www.dartlang.org/guides/language/effective-dart/usage#avoid-using-cast
        _socket.cast<Uint8List>().transform(_createLdapTransformer()).listen(
            (m) => _handleLDAPMessage(m),
            onError: _ldapListenerOnError,
            onDone: _ldapListenerOnDone);
      }

      return this;
    } on SocketException catch (e) {
      // For known error conditions (e.g. when the socket cannot be created)
      // throw a more meaningful exception. Otherwise, just rethrow it.

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
  }

  //----------------------------------------------------------------
  /// The handler for the listener for LDAP messages.
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
      loggeRecvLdap.fine(
          "Got extended response ${rop.responseName} code=${rop.ldapResult.resultCode}");
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

  //----------------------------------------------------------------
  /// The onError callback for the listener for LDAP messages.

  void _ldapListenerOnError(error, StackTrace stacktrace) {
    loggerConnection.finer("listen: onError", error, stacktrace);

    if (error is SocketException) {
      // Thrown a specific subclass of LdapSocketException if possible,
      // otherwise throw it as a generic LdapSocketException.

      if (error.osError != null) {
        if (error.osError.errorCode == 61) {
          // errorCode 61 = "Connection refused"
          throw new LdapSocketRefusedException(error, _host, _port);
        } else if (error.osError.errorCode == 8) {
          // errorCode 8 = "nodename nor servname provided, or not known"
          throw new LdapSocketServerNotFoundException(error, _host);
        }
      }
      throw new LdapSocketException(error);
    } else {
      throw error;
    }
  }

  //----------------------------------------------------------------
  /// The onDone callback for the listener for LDAP messages.
  ///
  /// This method will be invoked when the listener's stream is done.
  ///
  /// This can happen if the TCP/IP connect is broken.

  void _ldapListenerOnDone() {
    loggerConnection.finest("message stream done");

    assert(_whenDone != null);
    _whenDone.complete();

    _doClose();
  }

  //================================================================
  // Process LDAP operations

  //----------------------------------------------------------------
  /// Process an LDAP Search Request.
  ///
  /// Throws a [LdapUsageException] if the connection is closed.

  SearchResult processSearch(SearchRequest rop, List<Control> controls) {
    if (isClosed()) {
      throw new LdapUsageException("not connected");
    }

    var m = new LDAPMessage(++_nextMessageId, rop, controls);
    var op = new _StreamPendingOp(m);
    _queueOp(op);
    return op.searchResult;
  }

  //----------------------------------------------------------------
  /// Process a generic LDAP operation.
  ///
  /// This is used for processing all LDAP requests, except for
  /// LDAP search requests (which should use [processSearch]).
  ///
  /// Throws a [LdapUsageException] if the connection is closed.

  Future<LdapResult> process(RequestOp rop) {
    if (isClosed()) {
      throw new LdapUsageException("not connected");
    }

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

  //----------------------------------------------------------------

  /**
   * Return TRUE if there are messages waiting to be sent.
   *
   * Note that BIND is synchronous (as per LDAP spec) - so if there is a pending BIND
   * we must wait to send more messages until the BIND response comes back from the
   * server
   */
  bool _messagesToSend() =>
      (!_outgoingMessageQueue.isEmpty) && (_bindPending == false);

  //----------------------------------------------------------------
  // Send a single message to the server

  _sendMessage(_PendingOp op) {
    loggerSendLdap
        .fine("[${op.message.messageId}] Sending LDAP message: ${op.message}");

    var l = op.message.toBytes();

    loggerSendBytes.finest("[${op.message.messageId}] Bytes sending: $l");

    _socket.add(l);
    _pendingResponseMessages[op.message.messageId] = op;
    if (op.message.protocolTag == BIND_REQUEST) {
      _bindPending = true;
    }

    // Call the [flush] method so we can use [catchError] to detect errors
    // Note: this is experimental. So far no errors/exceptions have been seen.

    try {
      _socket.flush().then((v) {
        loggerSendBytes
            .finer("[${op.message.messageId}] Sent ${l.length} bytes");
      }).catchError((e) {
        loggerSendBytes.severe("[${op.message.messageId}] $e");
        throw e;
      });
    } catch (e) {
      loggerSendBytes.severe("[${op.message.messageId}] caught: $e");
      throw e;
    }
  }

  //================================================================
  // Disconnecting

  //----------------------------------------------------------------
  /**
   *
   *
   * Close the LDAP connection.
   *
   * Pending operations will be allowed to finish, unless immediate = true
   *
   * Returns a Future that is called when the connection is closed
   */

  Future close(bool immediate) async {
    if (immediate || _canClose()) {
      await _doClose();
    } else {
      loggerConnection.finer(
          "wait for queue to drain pendingResponse=$_pendingResponseMessages");

      var c = new Completer();
      // todo: dont wait if there are no pending ops....
      new Timer.periodic(PENDING_OP_TIMEOUT, (Timer t) {
        if (_canClose()) {
          t.cancel();
          _doClose().then((_) => c.complete());
        }
      });
      await c.future;
    }

    if (_whenDone != null) {
      loggerConnection.finest("wait for message stream to be done");
      await _whenDone.future; // wait for stream to be done
    }
  }

  //----------------------------------------------------------------
  /**
   * Return true if there are no more pending messages.
   */
  bool _canClose() {
    if (_pendingResponseMessages.isEmpty && _outgoingMessageQueue.isEmpty) {
      return true;
    }
    _sendPendingMessage();
    return false;
  }

  //----------------------------------------------------------------
  /// Closes the connection.

  Future _doClose() async {
    if (!isClosed()) {
      await _socket.close();
      _socket = null; // this marks the connection as being closed
    }
  }
}
