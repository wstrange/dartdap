import 'dart:async';

import 'dart:typed_data';
import '../protocol/ldap_protocol.dart';
import 'package:asn1lib/asn1lib.dart';

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
      logger.finest("Merging ${leftover.length}  bytes ");
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

    int count = 0; // count of total bytes consumed

    do {
      // only 1 byte? Can't possibly decode a length - wait for more bytes
      if (buf.length < 2) {
        leftover = buf;
        logger.finest("need at least 2 bytes in stream. Waiting for more");
        return;
      }
      // Try to determine the length of the ASN1 object so we
      // know how many bytes to expect in the stream
      // It is possible (but not likely) that this could throw a RangeError
      // if the stream does not have enough bytes to decode the length
      // This should be quite rare - so using an exception here is probably justified.
      int message_length = null;
      try {
        var asn1length = ASN1Length.decodeLength(buf);
        // asn1length computes the length of value bytes - so
        // add the start position in to get total message length
        message_length = asn1length.length + asn1length.valueStartPosition;
      } on RangeError catch (e) {
        logger.finest('Not enough bytes to decode length. Waiting for more');
        leftover = buf;
        return;
      }

      // length was decoded OK - so now see
      // If we have a full ldap message
      if (buf.length < message_length) {
        logger.finest(
            "buffer does not have enough bytes for a full LDAP message. Waiting for more bytes");
        leftover = buf;
        return;
      }

      try {
        var msg = new LDAPMessage.fromBytes(buf);
        assert(msg.messageLength == message_length);
        logger.finest(
            "Received LDAP message ${msg} size =${msg.messageLength}");
        sink.add(msg); // put it on the output stream
      } catch (e) {
        logger.severe(
            "Caught exception while trying to create ldap message, ${e.message}");
        // todo: Do we attempt to carry on and recover, or rethrow?
        throw (e);
      }

      // If no bytes remain we are done
      if (buf.length == message_length) {
        leftover = null; // and no extra bytes to process
        return;
      }

      // advance buffer window to next message
      count += message_length;
      buf = new Uint8List.view(data.buffer, count);
    } while (buf != null);
  }, handleError: (Object error, StackTrace st, EventSink<LDAPMessage> sink) {
    logger.severe("LDAP stream transformer: error=${error}, stacktrace=${st}");
    assert(false);
    throw error;
  });
}
