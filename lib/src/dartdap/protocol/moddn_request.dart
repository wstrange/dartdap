part of ldap_protocol;

/**
 * Modify DN Request.
 *
 * Rename a DN to a new RDN. Optionally delete the old entry and
 * reparent the DN to new superior.
 *
 *      ModifyDNRequest ::= [APPLICATION 12] SEQUENCE {
                entry           LDAPDN,
                newrdn          RelativeLDAPDN,
                deleteoldrdn    BOOLEAN,
                newSuperior     [0] LDAPDN OPTIONAL }
 *
 */
class ModDNRequest extends RequestOp {
  String _dn; // dn of entry we are adding
  String _newRDN; // new RDN
  bool _deleteOldRDN;
  String _newSuperiorDN;

  /**
   * Create a new modify DN (rename) request
   *
   * Rename the [_dn] to the new relative dn [_newRDN]. Delete
   * the old RDN (if [_deleteOldRDN] is true. If [_newSuperiorDN] is
   * not null the entry is reparented.
   *
   */
  ModDNRequest(this._dn, this._newRDN, this._deleteOldRDN, this._newSuperiorDN)
      : super(MODIFY_DN_REQUEST);

  ASN1Object toASN1() {
    var seq = _startSequence();
    seq.add(new ASN1OctetString(_dn));
    seq.add(new ASN1OctetString(_newRDN));
    seq.add(new ASN1Boolean(_deleteOldRDN));
    if (_newSuperiorDN != null) seq.add(new ASN1OctetString(_newSuperiorDN));
    return seq;
  }
}
