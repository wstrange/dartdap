part of ldap_protocol;

class AddRequest extends RequestOp {

  String _dn;     // dn of entry we are adding
  List<Attribute> _attributes; // attribute of object


  AddRequest(this._dn,this._attributes) :super(ADD_REQUEST);

  /*
   * Encode the add request to BER
   *
         AddRequest ::= [APPLICATION 8] SEQUENCE {
                    entry           LDAPDN,
                    attributes      AttributeList }

            AttributeList ::= SEQUENCE OF SEQUENCE {
                    type    AttributeDescription,
                    vals    SET OF AttributeValue }

  */

  ASN1Sequence toASN1Sequence() {
    var seq = _startSequence();
    seq.add(new ASN1OctetString(_dn));

   var attrSeq = new ASN1Sequence();

   _attributes.forEach((Attribute attr) {
     var s = new ASN1Sequence();
     s.add(new ASN1OctetString(attr.name));
     var ss = new ASN1Sequence();
     attr.values.forEach( (String val) {
       ss.add(new ASN1OctetString(val));
     });
     s.add(ss);
   });

   seq.add(attrSeq);

   return seq;
  }

}
