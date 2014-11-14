library control;

import 'package:asn1lib/asn1lib.dart';
import 'package:logging/logging.dart';
import '../sort_key.dart';



part 'virtual_list_view.dart';
part 'server_side_sort.dart';


var _clogger = new Logger("ldap_control");

/**
 * An LDAP Control
 *  See
 */
abstract class Control {
  static const VLV_RESPONSE = "2.16.840.1.113730.3.4.10";
  static const SERVER_SIDE_SORT_RESPONSE = "1.2.840.113556.1.4.474";

  static const CONTROLS_TAG = 0xA0; // seq encoding for controls

  String get oid;  // the LDAP OIN that represents this control
  bool isCritical = false;  // true if this control is critical (the server must implement)

  // Control subclasses must override this to return their encoded representation

  ASN1Sequence toASN1() => throw new Exception("Not implemented. Subclass must implement");

  /// Subclasses may may want to call this to start the encoding sequence. All
  /// controls start with the OID and a critical flag, followed by the
  /// optional encoded control values
  ASN1Sequence startSequence() {
    var seq = new ASN1Sequence(tag:CONTROLS_TAG);
    seq.add(new ASN1OctetString(oid));
    if( isCritical )
      seq.add(new ASN1Boolean(isCritical));
    return seq;
  }

  Control();

  static List<Control> parseControls(ASN1Sequence obj) {
    _clogger.finest("Create Controls from $obj");
    // todo: Parse the object, return
    var controls = [];

    if( obj != null) {
      obj.elements.forEach( (control) => controls.add( _parseControl(control) ));
    }
    return controls;

  }

  static _parseControl(ASN1Sequence s) {
    var oid = (s.elements.first as ASN1OctetString).stringValue;
    _clogger.finest("Got control $oid");
    switch(oid) {
      case VLV_RESPONSE:
        return new VLVResponseControl.fromASN1(s.elements[1]);
      case SERVER_SIDE_SORT_RESPONSE:
        return new ServerSideSortResponseControl.fromASN1(s.elements[1]);
      default:
        throw new Exception("Control $oid not implemented");
    }

  }

  String toString() => "$oid ${this.runtimeType}, isCritical=$isCritical}";

}

