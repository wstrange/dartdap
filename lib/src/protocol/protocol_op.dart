part of ldap_protocol;

class ProtocolOp {

  int _protocolOp;

  int get protocolOpCode  => _protocolOp;

  ProtocolOp(this._protocolOp);



  /**
   * Create a sequence that is the start of the protocol op
   * Sublclasses must add additional elements
   */
  ASN1Sequence _startSequence() {
    var seq = new ASN1Sequence(_protocolOp);

    return seq;
  }
}


abstract class RequestOp extends ProtocolOp {
  RequestOp(int opcode): super(opcode);

  /**
   * Subclasses must implement this method to convert their
   * representation to an ASN1Sequence
   */
  ASN1Sequence toASN1Sequence();
  /**
   * Encode this Request Operation to its BER Encoded form
   */
  Uint8List toEncodedBytes() {
    ASN1Sequence seq = toASN1Sequence();
    seq.encode();
    return seq.encodedBytes;
  }

}

class ResponseOp extends ProtocolOp {
  LDAPResult _ldapResult;
  int _opCode;


  LDAPResult get ldapResult => _ldapResult;

  ResponseOp(ASN1Sequence s) : super(s.tag){
    _ldapResult = _parseLDAPResult(s);
  }


  LDAPResult _parseLDAPResult(ASN1Sequence s) {
    ASN1Integer rc = s.elements[0];
    var resultCode = rc.intValue;

    var mv = s.elements[1] as ASN1OctetString;
    var matchedDN = mv.stringValue;
    var dm = s.elements[2] as ASN1OctetString;
    var diagnosticMessage = dm.stringValue;

    var refURLs = [];
    if( s.elements.length > 3) {
      // collect refs.... we dont really deal with these now...
      var rs = s.elements[3] as ASN1Sequence;
      refURLs = new List.from(rs.elements);
    }
    return new LDAPResult(resultCode, matchedDN, diagnosticMessage, refURLs);

  }

}


