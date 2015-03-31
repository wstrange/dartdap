import 'dart:async';

import 'dart:typed_data';
import '../protocol/ldap_protocol.dart';

Uint8List leftover = null; // TODO: fix this, must not be a static variable

// Create a transformer that transform a stream of
// raw bytes to a stream of LDAP messages

createTransformer() => new StreamTransformer.fromHandlers(
    handleData: (Uint8List data, EventSink<LDAPMessage> sink) {

      logger.finest("LDAP stream transformer: received ${data.length} bytes");

  var _buf;
  if (leftover == null) {
    // No left over bytes from before: just use the new data
    _buf = new Uint8List.view(data.buffer);
    ;
  } else {
    // There were left over bytes: concatenate the left over bytes with the new data
    _buf = new Uint8List(leftover.length + data.length);
    _buf.setRange(0, leftover.length, leftover);
    _buf.setRange(leftover.length, _buf.length, data);
    leftover = null;
  }

  do {
    // Try to determine the length of the next ASN1 object

    var value_size = null; // remains null if insufficient bytes to determine length
    var length_size;
    if (2 <= _buf.length) {
      // Enough data for the start of the length field
      int first_length_byte = _buf[1]; // length starts at position 1 (tag is at position 0)
      if (first_length_byte & 0x80 == 0) {
        // Single byte length
        length_size = 1;
        value_size = first_length_byte & 0x7F;
      } else {
        // Multi-byte length
        var num_length_bytes = (first_length_byte & 0x7F);
        if (2 + num_length_bytes <= _buf.length) {
          // Enough data for the entire length field
          length_size = 1 + num_length_bytes;
          value_size = 0;
          for (int x = 2; x < num_length_bytes + 2; x++) {
            value_size <<= 8;
            value_size |= _buf[x] & 0xFF;
          }
        }
      }
    }

    if (value_size != null && (1 + length_size + value_size) <= _buf.length) {
      // Sufficient data for the complete ASN1 object

      var message_size = (1 + length_size + value_size);

      logger.fine("LDAP stream transformer: ${message_size} bytes for ASN1 object: tag=${_buf[0]}, length=${value_size} value=${new Uint8List.view(_buf.buffer, 1 + length_size, value_size)}");

      if (_buf[0] == 10) {
        logger.finest("LDAP stream transformer: got a tag 10 object"); // this is seen in search results
      }
      var m = new LDAPMessage.fromBytes(_buf);
      assert(m.messageLength == message_size);
      logger.fine("Received LDAP message ${m}");
      sink.add(m);

      if (_buf.length == message_size) {
        _buf = null; // all bytes completely processed
      } else {
        _buf = new Uint8List.view(_buf.buffer, message_size); // keep unprocessed bytes
      }

    } else {
      // Insufficient data for a complete ASN1 object
      leftover = _buf; // save bytes until more data arrives
      _buf = null;
      logger.finest("LDAP stream transformer: incomplete ASN1 object: ${leftover.length} bytes retained (${leftover})");
      break; // stop processing the buffer
    }

  } while (_buf != null);
},

handleError: (Object error, StackTrace stackTrace, EventSink<LDAPMessage> sink) {
  assert(false);
  logger.severe("bytes to LDAPMessage transformer: error=${error}, stacktrace=${stackTrace}");
  throw error;

});
