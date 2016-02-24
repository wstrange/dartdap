part of ldap_protocol;

class AddRequest extends RequestOp {
  String _dn; // dn of entry we are adding
  Map<String, Attribute> _attributes; // attribute of object

  AddRequest(this._dn, Map<String, Attribute> this._attributes)
      : super(ADD_REQUEST);

  /*
   * Encode the add request to BER
   *
         AddRequest ::= [APPLICATION 8] SEQUENCE {
                    entry           LDAPDN,
                    attributes      AttributeList }

            AttributeList ::= SEQUENCE OF SEQUENCE {
                    type    AttributeDescription,
                    vals    SET OF AttributeValue }


  todo: Handle attribute values other than OctetString

  */

  ASN1Object toASN1() {
    var seq = _startSequence();
    seq.add(new ASN1OctetString(_dn));

    var attrSeq = new ASN1Sequence();

    _attributes.forEach((k, Attribute attr) {
      var s = new ASN1Sequence();
      s.add(new ASN1OctetString(attr.name));
      var ss = new ASN1Sequence();
      attr.values.forEach((dynamic val) {
        ss.add(new ASN1OctetString(val));
      });
      s.add(ss);
      attrSeq.add(s);
    });

    seq.add(attrSeq);

    return seq;
  }
}
