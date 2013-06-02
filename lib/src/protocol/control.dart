part of ldap_protocol;


/**
 * An LDAP Control
 */
class Control {
  String  oid;  // the LDAP OIN that represents this control
  bool isCritical;  // true if this control is critical (the server must implement)
  ASN1OctetString value; // the control Value


  ASN1Sequence toASN1() {
    var seq = new ASN1Sequence();
    seq.add(new ASN1OctetString(oid));
    if( isCritical )
      seq.add(new ASN1Boolean(isCritical));
    if( value != null)
      seq.add(value);
    return seq;
  }


}