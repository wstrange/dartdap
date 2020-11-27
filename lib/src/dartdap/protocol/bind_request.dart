part of ldap_protocol;

class BindRequest extends RequestOp {
  final String _bindDN;
  final String _password;

  //
  // * ASN1 encoding for Simple password bind type
  // * This is an octet string
  static const int CRED_TYPE_SIMPLE = 0x80;

  BindRequest(this._bindDN, this._password) : super(BIND_REQUEST);

  @override
  ASN1Object toASN1() {
    var seq = _startSequence();
    var version = ASN1Integer.fromInt(3); // alway v3
    seq.add(version);
    var bind_dn = ASN1OctetString(_bindDN);
    var pw = ASN1OctetString(_password, tag: CRED_TYPE_SIMPLE);
    seq.add(bind_dn);
    seq.add(pw);

    return seq;
  }
}
