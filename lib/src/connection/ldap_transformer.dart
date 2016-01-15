import 'dart:async';

import 'dart:typed_data';
import '../protocol/ldap_protocol.dart';
import 'package:logging/logging.dart';

/// Returns a [StreamTransformer<Uint8List,LDAPMessage>] that transform a stream
/// of bytes to a stream of LDAP messages.

StreamTransformer<Uint8List, LDAPMessage> createTransformer() {
  Uint8List leftover = null; // unused bytes from an earlier data event, or null

  return new StreamTransformer.fromHandlers(
      handleData: (Uint8List data, EventSink<LDAPMessage> sink) {
    // Set buf to the bytes to attempt to process: leftover bytes from an
    // earlier data event (if any) plus the new bytes in data.

    var buf;
    if (leftover == null) {
      // No left over bytes from before: new data only
      buf = new Uint8List.view(data.buffer);
      loggerRecvBytes.fine("Bytes received: ${data.length}");
    } else {
      // There were left over bytes: leftover bytes + new data
      buf = new Uint8List(leftover.length + data.length);
      buf.setRange(0, leftover.length, leftover);
      buf.setRange(leftover.length, buf.length, data);
      leftover = null;
      loggerRecvBytes
          .fine("Bytes received: ${data.length} (+${leftover.length} leftover)");
    }

    if (Level.FINEST <= loggerRecvBytes.level) {
      // If statement prevents this potentially computationally expensive
      // code to be executed if it is not needed.
      loggerRecvBytes.finest("Bytes received: ${data}");
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

        loggerRecvBytes.finer("Bytes parsed for ASN.1 object: $message_size");
        loggerRecvAsn1
            .fine("ASN.1 object received: tag=${buf[0]}, length=${value_size}");
        loggerRecvAsn1.finest(
            "ASN.1 value: ${new Uint8List.view(buf.buffer, 1 + length_size, value_size)}");

        if (buf[0] == 10) {
          // TODO: debug why this tag is not being parsed properly
          loggerRecvBytes
              .warning("LDAP stream transformer: got a tag 10 object");
        }

        // Create LDAPMessage from all the bytes of the complete ASN1 object.

        var msg = new LDAPMessage.fromBytes(buf);
        assert(msg.messageLength == message_size);

        // Put on output stream

        sink.add(msg);

        // Update buf: discard the message's bytes and keep any remaining
        // bytes. If no bytes remain, set buf to null to exit the do-while processing loop.

        if (buf.length == message_size) {
          // All bytes have been processed
          buf = null; // force do-while loop to exit
        } else {
          // Still some bytes unprocessed: leave for next iteration of do-while loop
          buf =
              new Uint8List.view(buf.buffer, buf.offsetInBytes + message_size);
        }
      } else {
        // Insufficient data for a complete ASN1 object.

        leftover = buf; // save bytes until more data arrives
        buf = null; // force do-while loop to exit
      }
    } while (buf != null);

    // Have processed as many of the bytes as possible.
    //
    // At this point, leftover is null if all the bytes have been consumed.
    // Otherwise, it contains the remaining bytes to be processed when more
    // bytes are received.
  }, handleError: (Object error, StackTrace st, EventSink<LDAPMessage> sink) {
    loggerRecvBytes
        .severe("LDAP stream transformer: error=${error}, stacktrace=${st}");
    assert(false);
    throw error;
  });
}

//EOF
