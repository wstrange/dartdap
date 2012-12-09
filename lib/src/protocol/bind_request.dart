part of ldap_protocol;

class BindRequest extends RequestOp {
  String _bindDN;
  String _password;

 /**
  * ASN1 encoding for Simple password bind type
  * This is an octet string
  **/
 const int CRED_TYPE_SIMPLE =  0x80;

  BindRequest(this._bindDN, this._password) :super(BIND_REQUEST) {

    _syncOp = true; // BIND must be syncronous
  }


  ASN1Sequence toASN1Sequence() {
    var seq = _startSequence();
    var version = new ASN1Integer(3); // alway v3
    seq.add(version);

    var bind_dn = new ASN1OctetString(_bindDN);
    var pw = new ASN1OctetString(_password);
    pw.tag = CRED_TYPE_SIMPLE;
    seq.add(bind_dn);
    seq.add(pw);

    return seq;
  }
}
