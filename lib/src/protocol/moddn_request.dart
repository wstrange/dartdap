part of 'ldap_protocol.dart';

//
// * Modify DN Request.
// *
// * Rename a DN to a new RDN. Optionally delete the old entry and
// * reparent the DN to new superior.
// *
// *      ModifyDNRequest ::= [APPLICATION 12] SEQUENCE {
//                entry           LDAPDN,
//                newrdn          RelativeLDAPDN,
//                deleteoldrdn    BOOLEAN,
//                newSuperior     [0] LDAPDN OPTIONAL }
//

class ModDNRequest extends RequestOp {
  final DN _dn; // dn of entry we are modifying
  final DN _newRDN; // new RDN
  final bool _deleteOldRDN;
  final DN? _newSuperiorDN;

  /// Create a new modify DN (rename) request
  ///
  /// Rename the [_dn] to the new relative dn [_newRDN]. Delete
  /// the old RDN (if [_deleteOldRDN] is true. If [_newSuperiorDN] is
  /// not null the entry is reparented.
  ///
  ModDNRequest(this._dn, this._newRDN, this._deleteOldRDN, this._newSuperiorDN)
      : super(MODIFY_DN_REQUEST);

  @override
  ASN1Object toASN1() {
    var seq = _startSequence();
    seq.add(ASN1OctetString(_dn.dn));
    seq.add(ASN1OctetString(_newRDN.dn));
    seq.add(ASN1Boolean(_deleteOldRDN));
    if (_newSuperiorDN != null) {
      seq.add(ASN1OctetString(_newSuperiorDN?.dn, tag: 0x80));
    }
    return seq;
  }
}
