import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import '../protocol/ldap_protocol.dart';

/// Returns a [StreamTransformer<Uint8List,LDAPMessage>] that transform a stream
/// of bytes to a stream of LDAP messages.

StreamTransformer<Uint8List, LDAPMessage> createLdapTransformer() {
  Uint8List? leftover; // unused bytes from an earlier data event, or null

  return StreamTransformer.fromHandlers(
      handleData: (Uint8List data, EventSink<LDAPMessage> sink) {
    if (data.isEmpty) {
      loggerRecvBytes.fine('received: zero');
      return;
    }
    // Set buf to the bytes to attempt to process: leftover bytes from an
    // earlier data event (if any) plus the new bytes in data.

    Uint8List buf;
    if (leftover == null) {
      // No left over bytes from before: new data only
      loggerRecvBytes.fine('received: ${data.length}');
      buf = Uint8List.view(data.buffer);
    } else {
      // There were left over bytes: leftover bytes + new data
      loggerRecvBytes
          .fine('received: ${data.length} (+${leftover!.length} leftover)');
      buf = Uint8List(leftover!.length + data.length);
      buf.setRange(0, leftover!.length, leftover!);
      buf.setRange(leftover!.length, buf.length, data);
      leftover = null;
    }

    // closure prevents expensive code to be executed if it is not needed.
    loggerRecvBytes.finest(() => 'received: $data');

    // Try to process the bytes, until there are not enough bytes left to form a
    // complete ASN1 object. Using a do-while loop because since this handleData
    // function was called, there will be at least some bytes to examine.

    assert(buf.isNotEmpty);

    do {
      // Try to determine the length of the next ASN1 object

      int? value_size; // null if insufficient bytes to determine length
      var length_size = 0; // number of bytes used by length field

      // todo: Would make sense to move this kind of logic into the asn1 package
      if (2 <= buf.length) {
        // Enough data for the start of the length field
        var firstLengthByte = buf[1]; // note: tag is at position 0
        if (firstLengthByte & 0x80 == 0) {
          // Single byte length field
          length_size = 1;
          value_size = firstLengthByte & 0x7F;
        } else {
          // Multi-byte length field
          var numLengthBytes = (firstLengthByte & 0x7F);
          if (2 + numLengthBytes <= buf.length) {
            // Enough data for the entire length field
            length_size = 1 + numLengthBytes;
            value_size = 0;
            for (var x = 2; x < numLengthBytes + 2; x++) {
              value_size = value_size! << 8;
              value_size |= buf[x] & 0xFF;
            }
          }
        }
      }

      if (value_size != null && (1 + length_size + value_size) <= buf.length) {
        // Got length and there is sufficient data for the complete ASN1 object

        var messageSize = (1 + length_size + value_size); // tag, length, data

        loggerRecvBytes.finer(() => 'parsed ASN.1 object: $messageSize bytes');
        loggerRecvAsn1.fine(
            () => 'ASN.1 object received: tag=${buf[0]}, length=$value_size');
        loggerRecvAsn1.finest(() =>
            'ASN.1 value: ${Uint8List.view(buf.buffer, 1 + length_size, value_size)}');

        if (buf[0] == 10) {
          // TODO: debug why this tag is not being parsed properly
          loggerRecvBytes
              .warning('LDAP stream transformer: got a tag 10 object');
        }

        // Create LDAPMessage from all the bytes of the complete ASN1 object.

        var msg = LDAPMessage.fromBytes(buf);
        assert(msg.messageLength == messageSize);

        // Put on output stream

        loggerConnection.finest('Adding message to sink m=$msg');

        sink.add(msg);

        // Update buf: discard the message's bytes and keep any remaining
        // bytes. If no bytes remain, set buf to null to exit the do-while processing loop.

        if (buf.length == messageSize) {
          // All bytes have been processed
          break;
        } else {
          // Still some bytes unprocessed: leave for next iteration of do-while loop
          buf = Uint8List.view(buf.buffer, buf.offsetInBytes + messageSize);
        }
      } else {
        // Insufficient data for a complete ASN1 object.

        leftover = buf; // save bytes until more data arrives
        break;
      }
    } while (true);

    // Have processed as many of the bytes as possible.
    //
    // At this point, leftover is null if all the bytes have been consumed.
    // Otherwise, it contains the remaining bytes to be processed when more
    // bytes are received.

    if (leftover == null) {
      loggerRecvBytes.finer('processed: all');
    } else {
      loggerRecvBytes.finer('processed: leftover ${leftover?.length} bytes');
    }
  }, handleError: (Object error, StackTrace st, EventSink<LDAPMessage> sink) {
    if (error is TlsException) {
      var e = error;
      if (e.osError == null &&
          e.message ==
              'OSStatus = -9805: connection closed gracefully error -9805') {
        // Connection closed gracefully: ignore this, since it occurs
        // due to application deliberately closing the connection
        loggerRecvBytes.finest(
            'LDAP stream transformer: closed gracefully${(leftover == null) ? '' : ': ${leftover?.length} bytes left over'}');
        return;
      }
    }
    loggerRecvBytes.severe('LDAP stream transformer: error=$error');
    throw error;
  }, handleDone: (EventSink<LDAPMessage> sink) {
    loggerRecvBytes.finest('LDAP stream transformer: byte stream done');
    sink.close();
  });
}
