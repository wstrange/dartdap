import 'dart:async';

import 'dart:typed_data';
import '../protocol/ldap_protocol.dart';

// Create a transformer that transform a stream of
// raw bytes to a stream of LDAP messages
createTransformer() => new StreamTransformer.fromHandlers(
    handleData: (Uint8List data, EventSink<LDAPMessage> sink) {
      var _buf = new Uint8List.view(data.buffer);
        var totalBytes = 0;
        while(_buf.length > 0) {
           var m = new LDAPMessage.fromBytes(_buf);
           logger.fine("Received LDAP message ${m}");
           sink.add(m);
           totalBytes += m.messageLength;
           _buf = new Uint8List.view(_buf.buffer,totalBytes);
        }
    });