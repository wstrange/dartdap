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
  static const CONTROLS = 0xA0; // seq encoding for controls

  String get oid;  // the LDAP OIN that represents this control
  String get controlName;
  bool isCritical = false;  // true if this control is critical (the server must implement)

  // Control subclasses must override this to return their encoded representation

  ASN1Sequence toASN1();

  /// Subclasses may may want to call this to start the encoding sequence. All
  /// controls start with the OID and a critical flag, followed by the
  /// optional encoded control values
  ASN1Sequence startSequence() {
    var seq = new ASN1Sequence(tag:CONTROLS);
    seq.add(new ASN1OctetString(oid));
    if( isCritical )
      seq.add(new ASN1Boolean(isCritical));
    return seq;
  }

  String toString() => "$controlName, isCritical=$isCritical asn1=${toASN1()}";

}

