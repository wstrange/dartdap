library connection_manager;


import 'dart:io';
import 'dart:async';
import 'dart:typeddata';
import 'dart:collection';

import 'package:logging/logging.dart';
import '../protocol/ldap_protocol.dart';

import '../filter.dart';
import '../ldap_exception.dart';
import '../ldap_result.dart';
import '../ldap_connection.dart';


/**
 * Holds a pending LDAP operation that we have issued to the server. We
 * expect to get a response back from the server for this op.
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

  bool processResult(ProtocolOp op) {
    if( op is SearchResultEntry ) {
      var re = (op as SearchResultEntry);
      controller.add(re.searchEntry);
      return false;
    }
    else { // we should be done now
      // if this is not a done message we are in trouble...
      var x = (op as SearchResultDone);

      if( x.ldapResult.resultCode != 0)
        controller.addError( new LDAPResultException(x.ldapResult));

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
    if( ldapResult.resultCode != 0)
      completer.completeError(ldapResult);
    else
      completer.complete(ldapResult);
    return true;
  }
}


/**
 * Manages the state of the LDAP connection
 */

class ConnectionManager {


  // Que for all outbound messages. We may need to buffer messages
  Queue<_PendingOp> _outgoingMessageQueue = new Queue<_PendingOp>();

  // Messages that we are expecting a response back from the LDAP server
  Map<int,_PendingOp> _pendingMessages = new Map();

/*
 *
 * todo: Can we get rid of this..
  static const CONNECTING = 1;
  static const CONNECTED = 2;
  static const CLOSED = 3;
   int _connectionState = CLOSED;
  */
  const TIMEOUT = const Duration(seconds: 3);

  bool _bindPending = false;

  Socket _socket;

  int _nextMessageId = 1;

  int _port;
  String _host;

  ConnectionManager(this._host,this._port);

  Function onError;

  Future<ConnectionManager> connect() {
    logger.finest("Creating socket to ${_host}:${_port}");

    var c = new Completer<ConnectionManager>();

    Socket.connect(_host,_port).then( (Socket sock) {
      logger.fine("Connected to $_host:$_port");
      //_connectionState = CONNECTED;
      _socket = sock;
      //sock.listen(_dataHandler,_errorHandler);
      sock.listen(_handleData);
      c.complete(this);
    }).catchError((AsyncError e) {
      logger.severe("Can't connect to $_host $_port");
      c.completeError(e);
    });;
    return c.future;

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
    _socket.writeBytes(l);
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
   */

  close(bool immediate) {
    if( immediate ) {
      _doClose();
    }
    else {
      new Timer.periodic(TIMEOUT, (Timer t) {
        if( _tryClose() ) {
          t.cancel();
        }
      });

    }
  }

  bool _tryClose() {
    if( _pendingMessages.isEmpty && _outgoingMessageQueue.isEmpty) {
      _doClose();
      return true;
    }

    logger.fine("close() waiting for queue to drain");
    _sendPendingMessage();
    return false;
  }

  _doClose() {
    logger.fine("Final Close");
    _socket.close();
    //_connectionState = CLOSED;
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
     _buf = data.getRange(i, data.length -i);
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
    /*
    if( _connection.onError != null) {
      _connection.onError(ex);
    }
    else {
      logger.warning("No error handler set for LDAPConnection");
      throw ex;
    }
    */
    throw ex;
  }

}
