part of ldap_protocol;

/**
 * Envelope for LDAP message protocol exchange
 *
 * See http://tools.ietf.org/html/rfc4511
 *
 *   LDAPMessage ::=
         SEQUENCE {
              messageID      MessageID,
              protocolOp     CHOICE {
                                  bindRequest         BindRequest,
                                  bindResponse        BindResponse,
                                  unbindRequest       UnbindRequest,
                                  searchRequest       SearchRequest,
                                  searchResEntry      SearchResultEntry,
                                  searchResDone       SearchResultDone,
                                  searchResRef        SearchResultReference,
                                  modifyRequest       ModifyRequest,
                                  modifyResponse      ModifyResponse,
                                  addRequest          AddRequest,
                                  addResponse         AddResponse,
                                  delRequest          DelRequest,
                                  delResponse         DelResponse,
                                  modifyDNRequest     ModifyDNRequest,
                                  modifyDNResponse    ModifyDNResponse,
                                  compareRequest      CompareRequest,
                                  compareResponse     CompareResponse,
                                  abandonRequest      AbandonRequest,
                                  extendedRequest     ExtendedRequest,
                                  extendedResponse    ExtendedResponse,
                                  ...,
                                  intermediateResponse IntermediateResponse
                             },
              controls       [0] Controls OPTIONAL
         }
 *
 *
 */
class LDAPMessage {
  int _messageId;
  int _protocolTag;

  int get protocolTag => _protocolTag;

  ASN1Sequence _protocolOp;
  ASN1Sequence _controls;
  //ASN1Sequence _obj;
  ASN1Object _obj;

  /// Return the ASN1 element at position i in the LDAP message
  /// This is used later when decoding the protocol operation
  /// to get at other elements in the message.
  List<ASN1Object> get elements => (_obj as ASN1Sequence).elements;

  /// return the message id sequence number.
  int get messageId => _messageId;

  ASN1Sequence get controls => _controls;
  // True if this message has LDAP controls
  bool get hasControls => _controls != null;

  /// return the [ASN1Sequence] that makes up this LDAP message
  ASN1Sequence get protocolOp => _protocolOp;

  /// the total length of this encoded message in bytes
  int get messageLength => _obj.totalEncodedByteLength;

  LDAPMessage(this._messageId, RequestOp rop, [List<Control> controls = null]) {
    _protocolTag = rop.protocolOpCode;
    _obj = rop.toASN1();
    if (controls != null && controls.length > 0) {
      _controls = new ASN1Sequence(tag: CONTROLS);
      controls.forEach((control) {
        _controls.add(control.toASN1());
        loggerSendLdap.finest("Adding control $control");
      });
    }
  }

  /// Constructs an LDAP message from list of raw bytes.
  /// Bytes will be parsed as an ASN1Sequence
  LDAPMessage.fromBytes(Uint8List bytes) {
    _obj = new ASN1Sequence.fromBytes(bytes);

    if (_obj == null) {
      throw new LdapParseException("Parsing error on ${bytes}");
    }
    if (elements.length != 2 && elements.length != 3) {
      throw new LdapParseException(
          "Expecting 2 or 3 elements: got ${elements.length} obj=$_obj");
    }

    var i = elements[0] as ASN1Integer;
    _messageId = i.intValue;

    _protocolOp = elements[1] as ASN1Sequence;

    _protocolTag = _protocolOp.tag;

    // Check if message has controls....
    if (elements.length == 3) {
      var c = elements[2].encodedBytes;
      if (c[0] == Control.CONTROLS_TAG)
        _controls = new ASN1Sequence.fromBytes(c);
    }
    loggeRecvLdap.fine(() =>
        "LDAP message received: Id=${messageId} protocolOp=${protocolOp}");
  }

  // Convert this LDAP message to a stream of ASN1 encoded bytes
  List<int> toBytes() {
    //logger.finest("Converting this object to bytes ${toString()}");
    ASN1Sequence seq = new ASN1Sequence();

    seq.add(ASN1Integer.fromInt(_messageId));

    seq.add(_obj);
    if (_controls != null) seq.add(_controls);

    var b = seq.encodedBytes;

    //var xx = LDAPUtil.toHexString(b);
    //logger.finest("LdapMesssage bytes = ${xx}");
    return b;
  }

  String toString() {
    var s = _op2String(_protocolTag);
    return "Msg(id=${_messageId}, op=${s},controls=$_controls)";
  }
}
