import 'control.dart';
import 'package:asn1lib/asn1lib.dart';
import 'sort_key.dart';

// https://tools.ietf.org/html/rfc2891

class ServerSideSortRequestControl extends Control {
  static const OID = '1.2.840.113556.1.4.473';
  @override
  String get oid => OID;

  // The BER type to use when encoding the orderingRule element.
  static const TYPE_ORDERING_RULE_ID = 0x80;

  // The BER type to use when encoding the reverseOrder element.
  static const TYPE_REVERSE_ORDER = 0x81;

  List<SortKey> sortKeys = [];

  ServerSideSortRequestControl(this.sortKeys);

  @override
  ASN1Sequence toASN1() {
    var seq = startSequence();

    var sortKeyseq = ASN1Sequence();

    sortKeys.forEach((key) {
      //_clogger.finest('Adding sort key $key');
      var s = ASN1Sequence();
      s.add(ASN1OctetString(key.attributeDescription));
      if (key.orderMatchingRule != null) {
        s.add(
            ASN1OctetString(key.orderMatchingRule, tag: TYPE_ORDERING_RULE_ID));
      }
      if (key.isReverseOrder) {
        var b = ASN1Boolean(true,
            tag:
                TYPE_REVERSE_ORDER); //todo: we should support tag override for asn1 bool
        s.add(b);
      }
      sortKeyseq.add(s);
    });
    // The control value is an octet string...
    seq.add(ASN1OctetString(sortKeyseq.encodedBytes));
    //_clogger.finest('asn1 = $seq');

    return seq;
  }
}

/// https://tools.ietf.org/html/rfc2891
class ServerSideSortResponseControl extends Control {
  // TODO: Are there any other codes we need...
  static final Map<int, String> SORT_RESULTS = {
    0: 'succes',
    1: 'operationsError',
    53: 'unwillingToPerform'
  };

  static const OID = '1.2.840.113556.1.4.474';
  @override
  String get oid => OID;
  late int sortResult;
  String attributeDescription = '';

  ServerSideSortResponseControl.fromASN1(ASN1OctetString s) {
    var seq = super.octetString2Sequence(s);
    var s2 = seq.elements.first as ASN1Sequence;
    sortResult = (s2.elements[0] as ASN1Integer).intValue;
    if (seq.elements.length == 2) {
      attributeDescription = (seq.elements[1] as ASN1OctetString).stringValue;
    }
  }

  static String _sortResult2Message(int r) =>
      SORT_RESULTS[r] ?? 'result code = $r';

  @override
  String toString() =>
      'ServerSideResponseControl. result: ${_sortResult2Message(sortResult)}, $attributeDescription';
}
