part of control;


class ServerSideSortRequestControl extends Control {

  String get oid => "1.2.840.113556.1.4.473";
  String get controlName => "ServerSideSortRequestControl";


  // The BER type to use when encoding the orderingRule element.
  static const TYPE_ORDERING_RULE_ID = 0x80;

  // The BER type to use when encoding the reverseOrder element.
  static const TYPE_REVERSE_ORDER = 0x81;

  List<SortKey> sortKeys = [];

  ServerSideSortRequestControl(this.sortKeys);

  ASN1Sequence toASN1() {
    var seq = startSequence();

    var sortKeyseq = new ASN1Sequence();

    sortKeys.forEach( (key) {
      _clogger.finest("Adding sort key $key");
      var s = new ASN1Sequence();
      s.add( new ASN1OctetString(key.attributeDescription));
      if( key.orderMatchingRule != null) {
        s.add( new ASN1OctetString(key.orderMatchingRule,tag:TYPE_ORDERING_RULE_ID));
      }
      if( key.isReverseOrder ) {
        var b = new ASN1Boolean(true); //todo: we should support tag override for asn1 bool
        b.tag = TYPE_REVERSE_ORDER; // override tag for CHOICE type
        s.add(b);
      }
      sortKeyseq.add(s);
    });
    var os = new ASN1OctetString(sortKeyseq.encodedBytes);
    seq.add(os);
    _clogger.finest("asn1 = $seq");

    return seq;
  }
}
