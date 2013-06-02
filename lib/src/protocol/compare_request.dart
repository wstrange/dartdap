part of ldap_protocol;

/**
 * Create a LDAP Compare Request
 *
 *    CompareRequest ::= [APPLICATION 14] SEQUENCE {
                entry           LDAPDN,
                ava             AttributeValueAssertion }

 */
class CompareRequest extends RequestOp {
  String  _dn;
  String  _attrName;
  dynamic _attrValue;

  CompareRequest(this._dn,this._attrName,this._attrValue):super(COMPARE_REQUEST);

  ASN1Object toASN1() {
    var seq = _startSequence();
    seq.add(new ASN1OctetString(_dn));

    var attrSeq = new ASN1Sequence();
    attrSeq.add(new ASN1OctetString(_attrName));
    attrSeq.add(new ASN1OctetString(_attrValue.toString()));
    seq.add(attrSeq);
    return seq;
  }


}