library connection_manager;

import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:collection';
import '../protocol/ldap_protocol.dart';

import '../ldap_exception.dart';
import '../ldap_result.dart';
import '../control/control.dart';


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
  bool processResult(ProtocolOp op);

}

// A pending op that has multiple values returned via a
// Stream. Used for SearchResults.
class _StreamPendingOp extends _PendingOp {

  _StreamPendingOp(LDAPMessage m):super(m);

  StreamController<SearchEntry> controller = new StreamController<SearchEntry>();

  // process the stream op - return false if we expect more data to come
  // or true if the search is complete
  bool processResult(ProtocolOp op) {
    // op is Search Entry. Add it to our stream and keep
    if( op is SearchResultEntry ) {
      controller.add(op.searchEntry);
      return false;
    }
    else { // we should be done now
      // if this is not a done message we are in trouble...
      var x = (op as SearchResultDone);

      // todo: how do we handle simple paged search here?
      // we need to launch another search request with the cookie
      // that we get from the ldap server

      if( x.ldapResult.resultCode != 0)
        controller.addError(x.ldapResult);

      controller.close();
    }
    return true; // op complete
  }
}

// A pending opertion that expects a single return response message
// returned via a future. For all LDAP ops except search results
class _FuturePendingOp extends _PendingOp {

  var completer = new Completer();

  _FuturePendingOp(LDAPMessage m):super(m);

  bool processResult(ProtocolOp op) {
    var ldapResult = (op as ResponseOp).ldapResult;
    if(_isError(ldapResult.resultCode))
      completer.completeError(ldapResult);
    else
      completer.complete(ldapResult);
    return true;
  }

  // return true if the result code is an error
  // any result code that you want to generate a [Future] error
  // should return true here. If the caller is normally
  // expecting to get a result code back this should return false.
  // example: for LDAP compare the caller wants to know the result
  // so we dont generate an error -but let the result code propagate back
  bool _isError(int resultCode) {
    switch( resultCode) {
      case 0:
      case ResultCode.COMPARE_TRUE:
      case ResultCode.COMPARE_FALSE:
        return false;
    }
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
  Map<int,_PendingOp> _pendingResponseMessages = new Map();

  // TIMEOUT when waiting for a pending op to come back from the server.
  static const PENDING_OP_TIMEOUT = const Duration(seconds: 6);
  //
  bool _bindPending = false; // true if a BIND is pending
  Socket _socket;

  int _nextMessageId = 1;  // message counter for this connection

  int _port;
  String _host;
  bool _ssl;

  ConnectionManager(this._host,this._port,this._ssl);


  Future<ConnectionManager> connect() async {
    logger.finest("Creating socket to ${_host}:${_port} ssl=$_ssl");
    var s = (_ssl ?  SecureSocket.connect(_host, _port, onBadCertificate:_badCertHandler) :
                    Socket.connect(_host,_port));

    _socket = await s;
    logger.fine("Connected to $_host:$_port");
    _socket.listen(_handleData,
        onError: (error) {
          logger.severe("Socket error = $error");
          throw new LDAPException("Socket error = $error");

        });
    return this;
  }

  // Called when the SSL cert is not valid
  // Return true to carry on anyways. TODO: Make it configurable
  bool _badCertHandler(X509Certificate cert) {
    logger.warning("Invalid Certificate issuer= ${cert.issuer} subject=${cert.subject}");
    logger.warning("SSL Connection will proceed. Please fix the certificate");
    return true; // carry on
  }

  // process an LDAP Search Request
  Stream<SearchEntry> processSearch(SearchRequest rop, List<Control> controls) {
    var m = new LDAPMessage(++_nextMessageId, rop,controls);
    var op = new _StreamPendingOp(m);
    _queueOp(op);
    return op.controller.stream;
  }

  // Process a generic LDAP operation.
  Future<LDAPResult> process(RequestOp rop) {
    var m = new LDAPMessage(++_nextMessageId, rop);
    var op = new _FuturePendingOp(m);
    _queueOp(op);
    return op.completer.future;
  }

  _queueOp(_PendingOp op) {
    _outgoingMessageQueue.add( op);
    _sendPendingMessage();
  }

  _sendPendingMessage() {
    logger.finest("Send pending message()");
    while( _messagesToSend() ) {
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
  bool _messagesToSend() =>  (! _outgoingMessageQueue.isEmpty ) && (_bindPending == false );


  // Send a single message to the server
  _sendMessage(_PendingOp op) {
    logger.fine("Sending message ${op.message}");
    var l = op.message.toBytes();
    _socket.add(l);
    _pendingResponseMessages[op.message.messageId] = op;
    if( op.message.protocolTag == BIND_REQUEST)
      _bindPending = true;
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
    if( immediate || _canClose() ) {
      return _doClose();
    }
    else {
      var c = new Completer();
      new Timer.periodic(PENDING_OP_TIMEOUT, (Timer t) {
        if( _canClose() ) {
          t.cancel();
          _doClose().then( (_) => c.complete());
        }
      });
      return c.future;
    }
  }

  /**
   * Return true if there are no more pending messages.
   */
  bool _canClose() {
    if( _pendingResponseMessages.isEmpty && _outgoingMessageQueue.isEmpty) {
      return true;
    }
    logger.finest("close() waiting for queue to drain pendingResponse=$_pendingResponseMessages");
    _sendPendingMessage();
    return false;
  }

  Future _doClose() {
    logger.fine("Final Close");
    var f = _socket.close();
    _socket = null;
    return f;
  }

  // handle incoming message bytes from the server
  // at this point this is just binary data
  // TODO: Broken. This can be called in a reentrant fashion
  // bytes from a previous call could still being processed. i/o (logging for example) could cause
  // this to not run to completion before the next batch of bytes is read on the socket.
  _handleData(Uint8List data) {

   logger.finest("ENTER ******* _handleData  bytes=${data.length} data=${data}");

   var _buf = new Uint8List.view(data.buffer);

   var bytesRead = 0;
   var totalBytes = 0;
   while(_buf.length > 0) {
     //logger.finest("TOP len=${_buf.length}  buf=$_buf");
     // pass binary buffer to handler. Handler
     // returns the number of bytes it consumed
     // when parsing the binary bits

     try {
      bytesRead = _handleMessage(_buf);
     }
     catch(e,stacktrace) {
       logger.severe("Exception while processing message. Exception $e");
       logger.severe(stacktrace);
       break;
     }
     //logger.finest("Message READ bytes=$bytesRead");


     totalBytes += bytesRead;
     //logger.finest("i=$i processed $bytesRead remaining = ${_buf.length - bytesRead}");

     _buf = new Uint8List.view(_buf.buffer,totalBytes);
     //logger.finest("**** remaining ${_buf.length} _buf=$_buf");
   }

   //logger.finest("EXIT +++++++ _handleData i=$i");

   _sendPendingMessage();
  }


  // parse the buffer into a LDAPMessage, and handle the message
  // return the number of bytes consumed
  int _handleMessage(Uint8List buffer) {
    //logger.finest("ENTER _handleMessage ${buffer.length} $buffer");
    // get a generic LDAP message envelope from the buffer
    var m = new LDAPMessage.fromBytes(buffer);
    logger.fine("Received LDAP message ${m} byte length=${m.messageLength}");

    // now call response handler to figure out what kind of resposnse
    // the message contains.
    var rop = ResponseHandler.handleResponse(m);
    // match it to a pending operation based on message id
    var pending_op = _pendingResponseMessages[m.messageId];

    // If this is not true, the server sent us possibly
    // malformed LDAP. What should we do?? Not clear if
    // we should throw an exception or try to ignore the error bytes
    // and carry on....
    if( pending_op == null )
      throw new LDAPException("Server sent us an unknown message id = ${m.messageId}");


    if( pending_op.processResult(rop) ) {
      // op is now complete. Remove it from pending q
      _pendingResponseMessages.remove(m.messageId);
    }

    if( m.protocolTag == BIND_RESPONSE)
      _bindPending = false;

    return m.messageLength;
  }

//  This was used for the pre-async code.
// Need to figure out if we still need this or not
//  _errorHandler(e) {
//    logger.severe("LDAP Error ${e}");
//    var ex = new LDAPException(e.toString());
//    throw ex;
//  }

}
