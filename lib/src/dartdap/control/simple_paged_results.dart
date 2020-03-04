import 'dart:typed_data';
import 'control.dart';
import 'package:asn1lib/asn1lib.dart';


/// A [Simple Paged Result Control](https://tools.ietf.org/html/rfc2696)
/// The client sends this control to the server to get back
/// paged results. The control is returned by the server. The cookie
/// value returned in the control should be used to fetch the next page
/// of results. See example/paged_search.dart for usage.
class SimplePagedResultsControl extends Control {
  @override
  static const OID = '1.2.840.113556.1.4.319';
  String get oid => OID;

  int size;
  List<int> _cookie;
  List<int> get cookie => _cookie;

  SimplePagedResultsControl({bool isCritical = false, this.size, List<int> cookie}) {
    if (isCritical) {
      // todo: refactor superclass - this should be immutable
      this.isCritical = isCritical;
    }
    _cookie = cookie == null ? Uint8List(0) : cookie;
  }

  // Return true if the cookie is empty. An empty cookie from the
  // server indicates there are no more paged results.
  bool get isEmptyCookie => _cookie == null || _cookie.isEmpty;

  /// pagedResultsControl ::= SEQUENCE {
  //        controlType     1.2.840.113556.1.4.319,
  //        criticality     BOOLEAN DEFAULT FALSE,
  //        controlValue    searchControlValue
  //}
  //
  //The searchControlValue is an OCTET STRING wrapping the BER-encoded
  //version of the following SEQUENCE:
  //
  //realSearchControlValue ::= SEQUENCE {
  //        size            INTEGER (0..maxInt),
  //                                -- requested page size from client
  //                                -- result set size estimate from server
  //        cookie          OCTET STRING
  //}
  ASN1Sequence toASN1() {
    var seq = startSequence();
    assert(_cookie != null);
    var s2 = ASN1Sequence();
    s2.add(ASN1Integer.fromInt(size));
    s2.add(ASN1OctetString(_cookie));
    // The sequence gets wrapped as an octetString
    seq.add( ASN1OctetString(s2.encodedBytes));
    return seq;
  }


  // Decode from an ASN1Sequence.
  // The parser has already unwrapped the OID and critical flag.
  // This is the payload - which a sequence wrapped as an octet string.
  SimplePagedResultsControl.fromASN1(ASN1OctetString s) {
    var wrapped =  octetString2Sequence(s);
    var seq = wrapped.elements[0] as ASN1Sequence;
    var _size = seq.elements[0] as ASN1Integer;
    size = _size.intValue;

    var _c = seq.elements[1] as ASN1OctetString;
    _cookie = _c.valueBytes();
  }

  String toString() => 'SimplePagedResultControl(size=$size, cookie="${_cookie}")';
}
