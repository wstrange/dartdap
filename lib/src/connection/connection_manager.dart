library connection_manager;

import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:collection';

import 'package:logging/logging.dart';
import '../protocol/ldap_protocol.dart';

import '../filter.dart';
import '../ldap_exception.dart';
import '../ldap_result.dart';
import '../ldap_connection.dart';


/**
 * Holds a pending LDAP operation that we have issued to the server. We
 * expect to get a response back from the server for this op. We match
 * against the message Id. example: We send request with id = 1234,
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
      var re = (op as SearchResultEntry);
      controller.add(re.searchEntry);
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

// A pending opertion that has a single return value
// returned via a future. For Everything but search results
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
  Map<int,_PendingOp> _pendingMessages = new Map();

  // TIMEOUT when waiting for a pending op.

  static const TIMEOUT = const Duration(seconds: 3);

  bool _bindPending = false;

  Socket _socket;

  int _nextMessageId = 1;

  int _port;
  String _host;
  bool _ssl;

  ConnectionManager(this._host,this._port,this._ssl);


  Future<ConnectionManager> connect() {
    logger.finest("Creating socket to ${_host}:${_port} ssl=$_ssl");

    var c = new Completer<ConnectionManager>();

    var s = _ssl ?  SecureSocket.connect(_host, _port, onBadCertificate:_badCertHandler) :
                    Socket.connect(_host,_port);

    s.then( (Socket sock) {
      logger.fine("Connected to $_host:$_port");
      //_connectionState = CONNECTED;
      _socket = sock;
      //sock.listen(_dataHandler,_errorHandler);
      sock.listen(_handleData);
      c.complete(this);
    }).catchError((e) {
      logger.severe("Can't connect to $_host $_port");
      c.completeError(e);
    });;
    return c.future;
  }

  // Called when the SSL cert is not valid
  // Return true to carry on anyways. TODO: Make it configurable
  bool _badCertHandler(X509Certificate cert) {
    logger.warning("Invalid Certificate issuer= ${cert.issuer} subject=${cert.subject}");
    logger.warning("SSL Connection will proceed. Please fix the certificate");
    return true; // carry on
  }

  // process an LDAP Search Request
  Stream<SearchEntry> processSearch(SearchRequest rop) {
    var m = new LDAPMessage(++_nextMessageId, rop);
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
    _pendingMessages[op.message.messageId] = op;
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
      new Timer.periodic(TIMEOUT, (Timer t) {
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
    if( _pendingMessages.isEmpty && _outgoingMessageQueue.isEmpty) {
      return true;
    }
    logger.fine("close() waiting for queue to drain");
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
  // at this point it is just binary data
  _handleData(List<int> data) {
   logger.fine("Got data $data");

   var _buf = data;
   int i = 0;
   while(true) {
     var bytesRead = _handleMessage(_buf);
     i += bytesRead;
     if( i >= data.length)
       break;
     // TODO: getRange is changing.
     //_buf = data.getRange(i, data.length);
     _buf = data.sublist(i);
   }

   _sendPendingMessage();
  }


  // parse the buffer into a LDAPMessage, and handle the message
  // return the number of bytes consumed
  int _handleMessage(Uint8List buffer) {
    // get a generic LDAP message envelope from the buffer
    var m = new LDAPMessage.fromBytes(buffer);
    logger.fine("Received LDAP message ${m} byte length=${m.messageLength}");

    // now call response handler to figure out what kind of resposnse
    // the message contains.
    var rop = ResponseHandler.handleResponse(m);

    var pending_op = _pendingMessages[m.messageId];

    assert (pending_op != null);


    if( pending_op.processResult(rop) ) {
      // op is now complete. Remove it from pending q
      _pendingMessages.remove(m.messageId);
    }

    if( m.protocolTag == BIND_RESPONSE)
      _bindPending = false;

    return m.messageLength;
  }


  _errorHandler(e) {
    logger.severe("LDAP Error ${e}");
    var ex = new LDAPException(e.toString());
    throw ex;
  }

}
