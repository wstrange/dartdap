library connection_manager;


import 'dart:io';
import 'dart:async';
import 'dart:scalarlist';
import 'dart:collection';

import 'package:logging/logging.dart';
import '../protocol/ldap_protocol.dart';

import '../filter.dart';
import '../ldap_exception.dart';
import '../ldap_result.dart';
import '../ldap_connection.dart';


/**
 * Records a pending LDAP operation that we have issued.
 *
 * todo: Implement timeouts?
 */
class PendingOp {

  Stopwatch _stopwatch = new Stopwatch()..start();

  bool _errorOnNonZero; // completer should throw error on non zero ldap result

  bool get errorOnNonZero => _errorOnNonZero;

  LDAPMessage message;
  final Completer  completer = new Completer();

  PendingOp(this.message,this._errorOnNonZero);

  String toString() => "PendingOp m=${message}";
}


/**
 * Manages the state of the LDAP connection
 */

class ConnectionManager {

  //LDAPConnection _connection;

  Queue<PendingOp> _outgoingMessageQueue = new Queue<PendingOp>();
  Map<int,PendingOp> _pendingMessages = new Map();


  static const CONNECTING = 1;
  static const CONNECTED = 2;
  static const CLOSED = 3;
  const TIMEOUT = const Duration(seconds: 3);

  bool _bindPending = false;

  int _connectionState = CLOSED;
  Socket _socket;

  int _nextMessageId = 1;

  LDAPConnection _connection;

  ConnectionManager(this._connection);

  Function onError;

  connect() {
    if( _connectionState == CONNECTED ) {
      return;
    }

    logger.finest("Creating socket to ${_connection.host}:${_connection.port}");
    _connectionState = CONNECTING;
    _bindPending = false;
    //_socket = new Socket.connect(_connection.host,_connection.port);

    Socket.connect(_connection.host,_connection.port).then( (Socket sock) {
      logger.fine("Connected to $_connection.host:$_connection.port");
      _connectionState = CONNECTED;
      _socket = sock;
      //sock.listen(_dataHandler,_errorHandler);
      sock.listen(_handleData);

      sendPendingMessage();
    });

  }


  Future process(RequestOp rop) {
    var m = new LDAPMessage(++_nextMessageId, rop);

    var op = new PendingOp(m,_connection.errorOnNonZeroResult);
    _outgoingMessageQueue.add( op);


    sendPendingMessage();
    return op.completer.future;
  }

  sendPendingMessage() {
    //logger.fine("Send pending messages");
    if( _connectionState == CONNECTING ) {
      logger.finest("Not connected or ready. Yielding");
      return;
    }

    while( _messagesToSend() ) {
      var op = _outgoingMessageQueue.removeFirst();
      _sendMessage(op);
    }
  }

  /**
   * Return TRUE if there are messages waiting to be sent.
   *
   * Note that BIND is synchronous (as per LDAP spec) - so if there is a pending BIND
   * we must wait to send more messages until the BIND response comes back
   */
  bool _messagesToSend() =>  (! _outgoingMessageQueue.isEmpty ) && (_bindPending == false );


  _sendMessage(PendingOp op) {
    logger.fine("Sending message ${op.message}");
    var l = op.message.toBytes();

    //_socket.writeList(l, 0,l.length);
    _socket.add(l);
    _pendingMessages[op.message.messageId] = op;
    if( op.message.protocolTag == BIND_REQUEST)
      _bindPending = true;
  }

/*
  _connectHandler() {
    logger.fine("Connected *****");
    _connectionState = CONNECTED;

    _socket.onData = _dataHandler;

    sendPendingMessage();
  }
  */

  /**
   *
   *
   * Close the LDAP connection.
   *
   * Pending operations will be allowed to finish, unless immediate = true
   */

  close({bool immediate:false}) {
    if( immediate ) {
      _doClose();
    }
    else {
      new Timer.repeating(TIMEOUT, (Timer t) {
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
    sendPendingMessage();
    return false;
  }

  _doClose() {
    _socket.close();
    _connectionState = CLOSED;
  }


  // parse the incoming LDAP message
  _handleData(List<int> data) {
   logger.fine("Got data $data");

   var _buf = data;
   int i = 0;
   while(true) {
     //var _buf = data.getRange(i,data.length-i);

     var bytesRead = _handleMessage(_buf);
     i += bytesRead;
     if( i >= data.length)
       break;
     _buf = data.getRange(i, data.length -i);
   }

   sendPendingMessage();
  }
    /*
    while( available > 0 ) {
      var buffer = new Uint8List(available);

      var count = _socket.readList(buffer,0, buffer.length);
      logger.finest("read ${count} bytes");
      //var s = listToHexString(buffer);
      //logger.finest("Bytes read = ${s}");


      // handle the message.
      // there could be more than one message here
      // so we keep track of how many bytes each message is
      // and continue parsing until we consume all of the bytes.
      var tempBuf = buffer;
      int bcount = tempBuf.length;


      while( bcount > 0) {
        int  bytesRead = _handleMessage(tempBuf);
        bcount = bcount - bytesRead;
        if(bcount > 0 ) {
          tempBuf = new Uint8List.view( tempBuf.asByteArray(bytesRead,bcount));
        }
      }

      sendPendingMessage(); // see if there are any pending messages
      available = _socket.available();
    }
    logger.finest("No more data, exiting _dataHandler");
  }
  */

  /// todo: what if search results come back out of order? Possible?
  ///
  int _handleMessage(Uint8List buffer) {
    var m = new LDAPMessage.fromBytes(buffer);
    logger.fine("Received LDAP message ${m} byte length=${m.messageLength}");

    var rop = ResponseHandler.handleResponse(m);

    if( rop is SearchResultEntry ) {
      handleSearchOp(rop);
    }
    else {
      // remove message from pending response map
      assert( _pendingMessages.containsKey(m.messageId));
      var op = _pendingMessages.remove(m.messageId);
      // if it is non zero - complete with catchError
      if( (rop.ldapResult.resultCode) > 0 && op.errorOnNonZero ) {
        op.completer.completeError( rop.ldapResult);
      }
      else {
        if( rop is SearchResultDone ) {
          logger.fine("Finished Search Results = ${searchResults}");
          searchResults.ldapResult = rop.ldapResult;

          op.completer.complete(searchResults);
          searchResults = new SearchResult(); // create new for next search
        }
        else {
          if( m.protocolTag == BIND_RESPONSE)
            _bindPending = false;
          op.completer.complete(rop.ldapResult);
        }
      }
    }

    return m.messageLength;
  }

  SearchResult searchResults = new SearchResult();

  void handleSearchOp(SearchResultEntry r) {
    logger.fine("Adding result ${r} ");
    searchResults.add(r.searchEntry);
  }

  _errorHandler(e) {
    logger.severe("LDAP Error ${e}");
    var ex = new LDAPException(e.toString());
    if( _connection.onError != null) {
      _connection.onError(ex);
    }
    else {
      logger.warning("No error handler set for LDAPConnection");
      throw ex;
    }
  }

}
