import 'dart:collection';
import 'dart:io';

import 'package:dartdap/dartdap.dart';

import '../protocol/ldap_protocol.dart';
import 'ldap_transformer.dart';
import 'dart:async';

/// Holds a pending LDAP operation that we have issued to the server. We
/// expect to get a response back from the server for this op. We match
/// the response against the message Id. example: We send request with id = 1234,
/// we expect a response with id = 1234
///
/// todo: Implement timeouts?
abstract class _PendingOp {
  final Stopwatch _stopwatch = Stopwatch()..start();

  // the message we are waiting for a response from
  LDAPMessage message;

  _PendingOp(this.message);

  @override
  String toString() => 'PendingOp m=$message';

  // Process an LDAP result. Return true if this operation is now complete
  bool processResult(ResponseOp op);

  void done() {
    var ms = _stopwatch.elapsedMilliseconds;
    loggerSendLdap.fine('LDAP request serviced: $message ($ms ms)');
  }
}

//================================================================

// A pending operation that has multiple values returned via a
// Stream. Used for SearchResults.
class _StreamPendingOp extends _PendingOp {
  final StreamController<SearchEntry> _controller =
      StreamController<SearchEntry>();
  late SearchResult _searchResult;
  SearchResult get searchResult => _searchResult;

  _StreamPendingOp(LDAPMessage m) : super(m) {
    _searchResult = SearchResult(_controller.stream);
  }

  // process the stream op - return false if we expect more data to come
  // or true if the search is complete
  @override
  bool processResult(ResponseOp op) {
    // op is Search Entry. Add it to our stream and keep
    if (op is SearchResultEntry) {
      _controller.add(op.searchEntry);
      return false;
    } else if (op is SearchResultDone) {
      // we should be done now
      // if this is not a done message we are in trouble...

      // SizeLimit Exceeded is not a true error. The partial
      // results from the server will be returned
      if (op.ldapResult.resultCode != ResultCode.OK &&
          op.ldapResult.resultCode != ResultCode.SIZE_LIMIT_EXCEEDED) {
        // Error result: convert to an exception class and add to controller
        _controller.addError(op.ldapResult.exceptionFromResultCode());
      }

      _searchResult.controls = op.controls;
      _searchResult.completeLdapResult(op.ldapResult);

      _controller.close();
      done();
    } else {
      // This is unexpected
      // TODO; Review. Can we recover better from this condition?
      _controller.addError(op.ldapResult.exceptionFromResultCode());
      _controller.close(); // TODO: Is the correct way to handle this?
      loggerConnection.severe('Unexpected op code = $op');
      done();
    }
    return true; // op complete
  }
}

//================================================================

// A pending operation that expects a single return response message
// returned via a future. For all LDAP ops except search results
class _FuturePendingOp extends _PendingOp {
  var completer = Completer<LdapResult>();

  _FuturePendingOp(LDAPMessage m) : super(m);

  @override
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

typedef BadCertHandlerType = bool Function(X509Certificate cert);

//================================================================

/// Manages the state of the LDAP connection.
///
/// Queues LDAP operations and sends them to the LDAP server.

class ConnectionManager {
  // Queue for all outbound messages.
  final Queue<_PendingOp> _outgoingMessageQueue = Queue<_PendingOp>();

  // Messages that we are expecting a response back from the LDAP server
  final Map<int, _PendingOp> _pendingResponseMessages = {};

  // TIMEOUT when waiting for a pending op to come back from the server.
  static const PENDING_OP_TIMEOUT = Duration(seconds: 10);
  //
  bool _bindPending = false; // true if a BIND is pending
  late Socket _socket;
  bool _isClosed = true;

  //----------------------------------------------------------------
  /// Indicates if the connection is closed.
  ///
  /// Returns true if the connection is closed, false otherwise.
  bool isClosed() => _isClosed;

  int _nextMessageId = 1; // message counter for this connection

  final SecurityContext? _context;

  final LdapConnection _connection;

  //----------------------------------------------------------------
  /// Constructor
  ///
  /// Creates and initializes a connection object.
  ///
  /// The actual TCP/IP connection is not established.
  ///

  ConnectionManager(this._connection,
      {SecurityContext? tlsSecurityContext})
      : _context = tlsSecurityContext ;

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

  static const _connectionTimeout = Duration(seconds: 30);

  Future<ConnectionManager> connect() async {
    try {
      if (isClosed()) {
        _socket = await (_connection.isSSL
            ? SecureSocket.connect(_connection.host, _connection.port,
                onBadCertificate: _connection.badCertHandler,
                context: _context,
                timeout: _connectionTimeout)
            : Socket.connect(_connection.host, _connection.port,
                timeout: _connectionTimeout));

        _socket.transform(createLdapTransformer()).listen(
            (m) => _handleLDAPMessage(m),
            onError: _ldapListenerOnError,
            onDone: _ldapListenerOnDone);

        _isClosed = false;
      }

      return this;
    } on SocketException catch (e) {
      // For known error conditions (e.g. when the socket cannot be created)
      // throw a more meaningful exception. Otherwise, just rethrow it.

      if (e.osError != null) {
        if (e.osError?.errorCode == 61) {
          // errorCode 61 = 'Connection refused'
          throw LdapSocketRefusedException(
              e, _connection.host, _connection.port);
        } else if (e.osError?.errorCode == 8) {
          // errorCode 8 = 'nodename nor servname provided, or not known'
          throw LdapSocketServerNotFoundException(e, _connection.host);
        }
      }
      rethrow;
    } catch (e) {
      loggerConnection.severe('Exception on connect', e);
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
    loggerRecvLdap.finest(
        'pendign = $_pendingResponseMessages, outgoing = $_outgoingMessageQueue');
    // call response handler to figure out what kind of resposnse
    // the message contains.
    var rop = ResponseHandler.handleResponse(m);
    // match it to a pending operation based on message id
    // todo: AN extended protocol op may not match an outstanding request
    // hanndle this case

    if (rop is ExtendedResponse) {
      loggerRecvLdap.fine(
          'Got extended response ${rop.responseName} code=${rop.ldapResult.resultCode}');
    }

    var pending_op = _pendingResponseMessages[m.messageId];

    // If this is not true, the server sent us possibly
    // malformed LDAP. What should we do??
    // On disconnect / shutdown server seems to send messageId = 0, 0x78 EXTENDED_RESPONSE
    if (pending_op == null) {
      var msg =
          'Server sent an unexpected message id = ${m.messageId} opCode=0x${m.protocolTag.toRadixString(16)}';
      loggerRecvLdap.severe(msg);
      //throw LdapParseException(msg);
      return;
    }

    if (pending_op.processResult(rop)) {
      // op is now complete. Remove it from pending q
      _pendingResponseMessages.remove(m.messageId);
    }

    if (m.protocolTag == BIND_RESPONSE) _bindPending = false;
  }

  //----------------------------------------------------------------
  /// The onError callback for the listener for LDAP messages.

  void _ldapListenerOnError(error, StackTrace stacktrace) {
    loggerConnection.finer('listen: onError', error, stacktrace);

    if (error is SocketException) {
      // Thrown a specific subclass of LdapSocketException if possible,
      // otherwise throw it as a generic LdapSocketException.

      if (error.osError != null) {
        if (error.osError?.errorCode == 61) {
          // errorCode 61 = 'Connection refused'
          throw LdapSocketRefusedException(
              error, _connection.host, _connection.port);
        } else if (error.osError?.errorCode == 8) {
          // errorCode 8 = 'nodename nor servname provided, or not known'
          throw LdapSocketServerNotFoundException(error, _connection.host);
        }
      }
      throw LdapSocketException(error);
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

  void _ldapListenerOnDone() async {
    loggerConnection.fine('socket stream closed');
    _connection.state = ConnectionState.error;
    await close();
    _connection.state = ConnectionState.closed;
  }

  //================================================================
  // Process LDAP operations

  //----------------------------------------------------------------
  /// Process an LDAP Search Request.
  ///
  /// Throws a [LdapUsageException] if the connection is closed.

  SearchResult processSearch(SearchRequest rop, List<Control> controls) {
    if (isClosed()) {
      throw LdapUsageException(
          'Connection is closed - cant process search result');
    }

    var m = LDAPMessage(++_nextMessageId, rop, controls);
    var op = _StreamPendingOp(m);
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
      throw LdapUsageException('not connected');
    }

    var m = LDAPMessage(++_nextMessageId, rop);
    var op = _FuturePendingOp(m);
    _queueOp(op);
    return op.completer.future;
  }

  void _queueOp(_PendingOp op) {
    _outgoingMessageQueue.add(op);
    _sendPendingMessage();
  }

  void _sendPendingMessage() {
    //logger.finest('Send pending message()');
    while (_messagesToSend()) {
      var op = _outgoingMessageQueue.removeFirst();
      _sendMessage(op);
    }
  }

  //----------------------------------------------------------------

  /// Return TRUE if there are messages waiting to be sent.
  ///
  /// Note that BIND is synchronous (as per LDAP spec) - so if there is a pending BIND
  /// we must wait to send more messages until the BIND response comes back from the
  /// server
  bool _messagesToSend() =>
      (_outgoingMessageQueue.isNotEmpty) && (_bindPending == false);

  //----------------------------------------------------------------
  // Send a single message to the server. Add the operation to
  // the pending response queue.
  void _sendMessage(_PendingOp op) {
    loggerSendLdap
        .fine('[${op.message.messageId}] Sending LDAP message: ${op.message}');

    sendLdapBytes(op.message);
    _pendingResponseMessages[op.message.messageId] = op;
    if (op.message.protocolTag == BIND_REQUEST) {
      _bindPending = true;
    }
  }

  // Call the [flush] method so we can use [catchError] to detect errors
  // Note: this is experimental. So far no errors/exceptions have been seen.
  // TODO: Expiriment with non flush
  // try {
  //   _socket?.flush().then((v) {
  //     loggerSendBytes
  //         .finer('[${op.message.messageId}] Sent ${l.length} bytes');
  //   }).catchError((e) {
  //     loggerSendBytes.severe('[${op.message.messageId}] $e');
  //     throw e;
  //   });
  // } catch (e) {
  //   loggerSendBytes.severe('[${op.message.messageId}] caught: $e');
  //   rethrow;
  // }

  // Send an Ldap Message to the server.
  void sendLdapBytes(LDAPMessage m) {
    var l = m.toBytes();
    loggerSendBytes.finest('[${m.messageId}] Bytes sending: $l');
    _socket.add(l);
  }

  //================================================================
  // Disconnecting

  //----------------------------------------------------------------
  ///
  ///
  /// Close the LDAP connection.
  ///
  /// Returns a Future that is called when the connection is closed

  Future<void> close() async {
    loggerConnection.finer('Closing connection');
    if (!_canClose()) {
      loggerConnection.warning('Trying to close connection that is pending!');
    }
    _socket.destroy();
    _isClosed = true;
  }

  //----------------------------------------------------------------
  /// Return true if there are no more pending messages.
  bool _canClose() {
    if (_pendingResponseMessages.isEmpty && _outgoingMessageQueue.isEmpty) {
      return true;
    }
    _sendPendingMessage();
    return false;
  }
}
