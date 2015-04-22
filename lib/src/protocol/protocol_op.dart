part of ldap_protocol;


// todo: Do we need this base class. Really only applies to requests

class ProtocolOp {
  int _protocolOp;
  int get protocolOpCode  => _protocolOp;
  ProtocolOp(this._protocolOp);

  /**
   * Create a sequence that is the start of the protocol op
   * Sublclasses must add additional elements
   */
  ASN1Sequence _startSequence() {
    var seq = new ASN1Sequence(tag:_protocolOp);
    return seq;
  }
}


abstract class RequestOp extends ProtocolOp {
  RequestOp(int opcode): super(opcode);

  /**
   * Subclasses must implement this method to convert their
   * representation to an ASN1Sequence
   */
  ASN1Object toASN1();
  /**
   * Encode this Request Operation to its BER Encoded form
   */
  Uint8List toEncodedBytes() {
    ASN1Sequence seq = toASN1();
    return seq.encodedBytes;
  }

}

class ResponseOp {
  LDAPResult _ldapResult;
  List<Control> _controls = [];

  List<Control> get controls => _controls;
  int _opCode;

  // type for LDAP refereals urls in ldapresults
  static const int TYPE_REFERRAL_URLS = 0xA3;

  LDAPResult get ldapResult => _ldapResult;

  ResponseOp.searchEntry(); // needed for SearchResultEntry - that does not have an LDAPMessage

  ResponseOp(LDAPMessage m) {
    logger.finest("+++++ new response op = $m");
    _ldapResult = _parseLDAPResult(m.protocolOp);
    // Parse controls;
    if( m.hasControls )
      _controls = Control.parseControls(m._controls);
  }

  // parse the embedded LDAP Response
  LDAPResult _parseLDAPResult(ASN1Sequence s) {
    logger.finest("parse ldap result == $s");
    ASN1Integer rc = s.elements[0];
    var resultCode = rc.intValue;

    var mv = s.elements[1] as ASN1OctetString;
    var matchedDN = mv.stringValue;
    var dm = s.elements[2] as ASN1OctetString;
    var diagnosticMessage = dm.stringValue;

    var refURLs = [];
    if( s.elements.length > 3) {
      var o = s.elements[3];
      logger.fine("parse LDAP Result type = $o");
      // collect refs.... we dont really deal with these now...
      //var rs = s.elements[3] as ASN1Sequence;
      //refURLs = new List.from(rs.elements);

      /*
       *   case TYPE_REFERRAL_URLS:
            final ArrayList<String> refList = new ArrayList<String>(1);
            final ASN1StreamReaderSequence refSequence = reader.beginSequence();
            while (refSequence.hasMoreElements())
            {
              refList.add(reader.readString());
            }
            referralURLs = new String[refList.size()];
            refList.toArray(referralURLs);
            break;

          case TYPE_EXTENDED_RESPONSE_OID:
            oid = reader.readString();
            break;

          case TYPE_EXTENDED_RESPONSE_VALUE:
            value = new ASN1OctetString(type, reader.readBytes());
            break;
       *
       */
    }
    return new LDAPResult(resultCode, matchedDN, diagnosticMessage, refURLs);
  }
}


