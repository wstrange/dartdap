import 'simple_paged_results.dart';
import 'package:logging/logging.dart';
import 'package:asn1lib/asn1lib.dart';
import 'virtual_list_view.dart';
import 'server_side_sort.dart';

export 'virtual_list_view.dart';
export 'server_side_sort.dart';
export 'sort_key.dart';
export 'simple_paged_results.dart';

/// Logger for the control section of dartdap.

Logger clogger = Logger('ldap.control');

/// An LDAP Control
abstract class Control {
//  static const VLV_REQUEST = '2.16.840.1.113730.3.4.9';
//  static const VLV_RESPONSE = '2.16.840.1.113730.3.4.10';
//
//  static const SERVER_SIDE_SORT_REQUEST = '1.2.840.113556.1.4.473';
//  static const SERVER_SIDE_SORT_RESPONSE = '1.2.840.113556.1.4.474';

  String get oid;

  static const CONTROLS_TAG = 0xA0; // seq encoding for controls

  bool isCritical =
      false; // true if this control is critical (the server must implement)

  // Control subclasses must override this to return their encoded representation

  ASN1Sequence toASN1() =>
      throw Exception('Not implemented. Subclass must implement');

  /// Subclasses may want to call this to start the encoding sequence. All
  /// controls start with the OID and a critical flag, followed by the
  /// optional encoded control values
  ASN1Sequence startSequence() {
    var seq = ASN1Sequence();
    seq.add(ASN1OctetString(oid));
    if (isCritical) seq.add(ASN1Boolean(isCritical));
    return seq;
  }

  Control();

  static List<Control> parseControls(ASN1Sequence obj) {
    clogger.finest('Create Controls from $obj');
    // todo: Parse the object, return
    var controls = <Control>[];

    for (var control in obj.elements) {
      var c = _parseControl(control as ASN1Sequence);
      if (c != null) {
        controls.add(c);
      }
    }
    return controls;
  }

  static Control? _parseControl(ASN1Sequence s) {
    var oid = (s.elements.first as ASN1OctetString).stringValue;
    clogger.finest('Got control $oid');
    switch (oid) {
      case VLVResponseControl.OID:
        return VLVResponseControl.fromASN1(s.elements[1] as ASN1OctetString);
      case ServerSideSortResponseControl.OID:
        return ServerSideSortResponseControl.fromASN1(
            s.elements[1] as ASN1OctetString);
      case SimplePagedResultsControl.OID:
        return SimplePagedResultsControl.fromASN1(
            s.elements[1] as ASN1OctetString);
      default:
        clogger.warning('Control $oid not implemented');
    }
    return null;
  }

  // Some ldap controls wrap a sequence as an octet string.
  // this unwraps those back to a sequence.
  ASN1Sequence octetString2Sequence(ASN1OctetString s) {
    var bytes = s.encodedBytes;
    bytes[0] = SEQUENCE_TYPE | CONSTRUCTED_BIT;
    return ASN1Sequence.fromBytes(bytes);
  }

  @override
  String toString() => '$oid $runtimeType, isCritical=$isCritical}';
}
