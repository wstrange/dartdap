part of ldap_protocol;

// todo: Do we need this base class. Really only applies to requests

class ProtocolOp {
  final int _protocolOp;
  int get protocolOpCode => _protocolOp;
  ProtocolOp(this._protocolOp);

  /// Create a sequence that is the start of the protocol op
  /// Sublclasses must add additional elements
  ASN1Sequence _startSequence() {
    var seq = ASN1Sequence(tag: _protocolOp);
    return seq;
  }
}

abstract class RequestOp extends ProtocolOp {
  RequestOp(int opcode) : super(opcode);

  /// Subclasses must implement this method to convert their
  /// representation to an ASN1Sequence
  ASN1Object toASN1();

  /// Encode this Request Operation to its BER Encoded form
  Uint8List toEncodedBytes() {
    var seq = toASN1() as ASN1Sequence;
    return seq.encodedBytes;
  }
}

class ResponseOp {
  late LdapResult _ldapResult;
  List<Control> _controls = [];

  List<Control> get controls => _controls;
  // int _opCode;

  // type for LDAP refereals urls in ldapresults
  static const int TYPE_REFERRAL_URLS = 0xA3;

  LdapResult get ldapResult => _ldapResult;

  //
  ResponseOp.searchEntry(); // needed for SearchResultEntry - that does not have an LDAPMessage

  ResponseOp(LDAPMessage m) {
    loggerRecvLdap.finer(() => 'Response op=$m');
    _ldapResult = _parseLDAPResult(m.protocolOp);
    // Parse controls;
    if (m.hasControls) _controls = Control.parseControls(m._controls);
  }

  // parse the embedded LDAP Response
  LdapResult _parseLDAPResult(ASN1Sequence s) {
    loggerRecvLdap.finer('Parse LDAP result: $s');
    var rc = s.elements[0] as ASN1Integer;
    var resultCode = rc.intValue;

    var mv = s.elements[1] as ASN1OctetString;
    var matchedDN = mv.stringValue;
    var dm = s.elements[2] as ASN1OctetString;
    var diagnosticMessage = dm.stringValue;

    var refURLs = <String>[];
    if (s.elements.length > 3) {
      var o = s.elements[3];
      loggerRecvLdap.finer('Parse LDAP result: type=$o');
      // collect refs.... we dont really deal with these now...
      //var rs = s.elements[3] as ASN1Sequence;
      //refURLs = List.from(rs.elements);

      /*
       *   case TYPE_REFERRAL_URLS:
            final ArrayList<String> refList = ArrayList<String>(1);
            final ASN1StreamReaderSequence refSequence = reader.beginSequence();
            while (refSequence.hasMoreElements())
            {
              refList.add(reader.readString());
            }
            referralURLs = String[refList.size()];
            refList.toArray(referralURLs);
            break;

          case TYPE_EXTENDED_RESPONSE_OID:
            oid = reader.readString();
            break;

          case TYPE_EXTENDED_RESPONSE_VALUE:
            value = ASN1OctetString(type, reader.readBytes());
            break;
       *
       */
    }
    return LdapResult(resultCode, matchedDN, diagnosticMessage, refURLs);
  }
}
