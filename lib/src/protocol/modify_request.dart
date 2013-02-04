part of ldap_protocol;


/**
 * LDAP Modify Request
 */
class ModifyRequest extends RequestOp {

  String _dn;     // dn of entry we are adding
  List<Modification> _mods; // modifications to make


  ModifyRequest(this._dn,this._mods) :super(MODIFY_REQUEST);

  /*

  ModifyRequest ::= [APPLICATION 6] SEQUENCE {
  object          LDAPDN,
  modification    SEQUENCE OF SEQUENCE {
  operation       ENUMERATED {
  add     (0),
  delete  (1),
  replace (2) },
  modification    AttributeTypeAndValues } }


   */

  ASN1Object toASN1() {
    var seq = _startSequence();
    seq.add(new ASN1OctetString(_dn));

   var modSeq = new ASN1Sequence();

   _mods.forEach((Modification m) {
     var s = new ASN1Sequence();
     s.add(new ASN1Integer(m.operation));
     s.add(_encodeAttrTypeAndValues(m.attributeName,m.values));
     modSeq.add(s);
   });

   seq.add(modSeq);

   return seq;
  }

  // encode the attribute type and set of values
  /*
   * AttributeTypeAndValues ::= SEQUENCE {
  type    AttributeDescription,
  vals    SET OF AttributeValue }
  */

  ASN1Sequence _encodeAttrTypeAndValues(String attrName, List values) {
    var s = new ASN1Sequence();
    s.add( new ASN1OctetString(attrName));
    var ss = new ASN1Sequence();
    values.forEach( (v) {  ss.add(new ASN1OctetString(v));});
    s.add(ss);
    return s;
  }

}