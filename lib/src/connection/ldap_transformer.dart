import 'dart:async';

import 'dart:typed_data';
import '../protocol/ldap_protocol.dart';

/// Returns a [StreamTransformer<Uint8List,LDAPMessage>] that transform a stream
/// of bytes to a stream of LDAP messages.

StreamTransformer<Uint8List, LDAPMessage> createTransformer() {
  Uint8List leftover = null; // unused bytes from an earlier data event, or null

  return new StreamTransformer.fromHandlers(
      handleData: (Uint8List data, EventSink<LDAPMessage> sink) {
    logger.finest("LDAP stream transformer: received ${data.length} bytes");

    // Set buf to the bytes to attempt to process: leftover bytes from an
    // earlier data event (if any) plus the new bytes in data.

    var buf;
    if (leftover == null) {
      // No left over bytes from before: new data only
      buf = new Uint8List.view(data.buffer);
    } else {
      // There were left over bytes: leftover bytes + new data
      buf = new Uint8List(leftover.length + data.length);
      buf.setRange(0, leftover.length, leftover);
      buf.setRange(leftover.length, buf.length, data);
      leftover = null;
    }

    // Try to process the bytes, until there are not enough bytes left to form a
    // complete ASN1 object. Using a do-while loop because since this handleData
    // function was called, there will be at least some bytes to examine.

    assert(0 < buf.length);

    do {
      // Try to determine the length of the next ASN1 object

      var value_size = null; // null if insufficient bytes to determine length
      var length_size; // number of bytes used by length field

      if (2 <= buf.length) {
        // Enough data for the start of the length field
        int first_length_byte = buf[1]; // note: tag is at position 0
        if (first_length_byte & 0x80 == 0) {
          // Single byte length field
          length_size = 1;
          value_size = first_length_byte & 0x7F;
        } else {
          // Multi-byte length field
          var num_length_bytes = (first_length_byte & 0x7F);
          if (2 + num_length_bytes <= buf.length) {
            // Enough data for the entire length field
            length_size = 1 + num_length_bytes;
            value_size = 0;
            for (int x = 2; x < num_length_bytes + 2; x++) {
              value_size <<= 8;
              value_size |= buf[x] & 0xFF;
            }
          }
        }
      }

      if (value_size != null && (1 + length_size + value_size) <= buf.length) {
        // Got length and there is sufficient data for the complete ASN1 object

        var message_size = (1 + length_size + value_size); // tag, length, data

        logger.fine(
            "LDAP stream transformer: ${message_size} bytes for ASN1 object: tag=${buf[0]}, length=${value_size} value=${new Uint8List.view(buf.buffer, 1 + length_size, value_size)}");

        if (buf[0] == 10) {
          // TODO: debug why this tag is not being parsed properly
          logger.finest("LDAP stream transformer: got a tag 10 object");
        }

        // Create LDAPMessage from all the bytes of the complete ASN1 object.

        var msg = new LDAPMessage.fromBytes(buf);
        assert(msg.messageLength == message_size);
        logger.fine("Received LDAP message ${msg}");
        sink.add(msg); // put on output stream

        // Update buf: discard the message's bytes and keep any remaining
        // bytes. If no bytes remain, set buf to null to exit the do-while processing loop.

        if (buf.length == message_size) {
          buf = null; // all bytes completely processed
        } else {
          buf = new Uint8List.view(buf.buffer, buf.offsetInBytes + message_size);
        }
      } else {
        // Insufficient data for a complete ASN1 object.

        leftover = buf; // save bytes until more data arrives
        buf = null; // so the do-while processing loop exits

        logger.finest(
            "LDAP stream transformer: incomplete ASN1 object: ${leftover.length} bytes retained (${leftover})");
      }
    } while (buf != null);
  }, handleError: (Object error, StackTrace st, EventSink<LDAPMessage> sink) {
    logger.severe("LDAP stream transformer: error=${error}, stacktrace=${st}");
    assert(false);
    throw error;
  });
}

//EOF
