part of 'ldap_protocol.dart';

/// LDAP Modify Request
class ModifyRequest extends RequestOp {
  final DN _dn; // dn of entry we are adding
  final List<Modification> _mods; // modifications to make

  ModifyRequest(this._dn, this._mods) : super(MODIFY_REQUEST);

  // ModifyRequest ::= [APPLICATION 6] SEQUENCE {
  // object          LDAPDN,
  // modification    SEQUENCE OF SEQUENCE {
  // operation       ENUMERATED {
  // add     (0),
  // delete  (1),
  // replace (2) },
  // modification    AttributeTypeAndValues } }

  @override
  ASN1Object toASN1() {
    var seq = _startSequence();
    seq.add(_dn.octetString);

    var modSeq = ASN1Sequence();

    for (var m in _mods) {
      var s = ASN1Sequence();
      // Fix for #21 - this should be an enum.
      s.add(ASN1Enumerated(m.operation));
      s.add(_encodeAttrTypeAndValues(m.attributeName, m.values));
      modSeq.add(s);
    }

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
    var s = ASN1Sequence();
    s.add(ASN1OctetString(attrName));
    // Fix for #21 - this should be a Set, not a Sequence
    var ss = ASN1Set();
    for (var v in values) {
      ss.add(ASN1OctetString(v));
    }
    s.add(ss);
    return s;
  }
}
