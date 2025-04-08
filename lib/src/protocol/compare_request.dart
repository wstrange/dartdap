part of 'ldap_protocol.dart';

// Create a LDAP Compare Request
//
//  CompareRequest ::= [APPLICATION 14] SEQUENCE {
//                 entry           LDAPDN,
//                 ava             AttributeValueAssertion }

class CompareRequest extends RequestOp {
  final DN _dn;
  final String _attrName;
  final dynamic _attrValue;

  CompareRequest(this._dn, this._attrName, this._attrValue) : super(COMPARE_REQUEST);

  @override
  ASN1Object toASN1() {
    var seq = _startSequence();
    seq.add(_dn.octetString);

    var attrSeq = ASN1Sequence();
    attrSeq.add(ASN1OctetString(_attrName));
    attrSeq.add(ASN1OctetString(_attrValue.toString()));
    seq.add(attrSeq);
    return seq;
  }
}
