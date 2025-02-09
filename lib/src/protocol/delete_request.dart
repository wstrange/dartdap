part of 'ldap_protocol.dart';

class DeleteRequest extends RequestOp {
  final DN _dn; // dn of entry we are deleting

  DeleteRequest(this._dn) : super(DELETE_REQUEST);

  //
  // Encode the add request to BER
  //
  //      DelRequest ::= [APPLICATION 10] LDAPDN

  @override
  ASN1Object toASN1() => ASN1OctetString(_dn.dn, tag: DELETE_REQUEST);
}
