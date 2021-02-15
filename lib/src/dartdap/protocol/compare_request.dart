part of ldap_protocol;


// Create a LDAP Compare Request
//
//  CompareRequest ::= [APPLICATION 14] SEQUENCE {
//                 entry           LDAPDN,
//                 ava             AttributeValueAssertion }

class CompareRequest extends RequestOp {
  final String _dn;
  final String _attrName;
  final dynamic _attrValue;

  CompareRequest(this._dn, this._attrName, this._attrValue)
      : super(COMPARE_REQUEST);

  @override
  ASN1Object toASN1() {
    var seq = _startSequence();
    seq.add(ASN1OctetString(_dn));

    var attrSeq = ASN1Sequence();
    attrSeq.add(ASN1OctetString(_attrName));
    attrSeq.add(ASN1OctetString(_attrValue.toString()));
    seq.add(attrSeq);
    return seq;
  }
}
