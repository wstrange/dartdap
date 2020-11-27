part of ldap_protocol;

class AddRequest extends RequestOp {
  final String _dn; // dn of entry we are adding
  final Map<String, Attribute> _attributes; // attribute of object

  AddRequest(this._dn, this._attributes)
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

  @override
  ASN1Object toASN1() {
    var seq = _startSequence();
    seq.add(ASN1OctetString(_dn));

    var attrSeq = ASN1Sequence();

    _attributes.forEach((k, Attribute attr) {
      var s = ASN1Sequence();
      s.add(ASN1OctetString(attr.name));
      var ss = ASN1Set(); // fixes #21
      attr.values.forEach((dynamic val) {
        ss.add(ASN1OctetString(val));
      });
      s.add(ss);
      attrSeq.add(s);
    });

    seq.add(attrSeq);

    return seq;
  }
}
