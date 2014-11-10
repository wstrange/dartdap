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
                                  searchResponse      SearchResponse,
                                  modifyRequest       ModifyRequest,
                                  modifyResponse      ModifyResponse,
                                  addRequest          AddRequest,
                                  addResponse         AddResponse,
                                  delRequest          DelRequest,
                                  delResponse         DelResponse,
                                  modifyRDNRequest    ModifyRDNRequest,
                                  modifyRDNResponse   ModifyRDNResponse,
                                  compareDNRequest    CompareRequest,
                                  compareDNResponse   CompareResponse,
                                  abandonRequest      AbandonRequest
                             }
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


  ASN1Object _obj;

  /// return the message id sequence number.
  int get messageId => _messageId;

  /// return the [ASN1Sequence] that makes up this LDAP message
  ASN1Sequence get protocolOp => _protocolOp;

  /// the total length of this encoded message in bytes
  int get messageLength => _obj.totalEncodedByteLength;


  LDAPMessage(this._messageId,RequestOp rop,[List<Control> controls = null]) {
    _protocolTag = rop.protocolOpCode;
    _obj = rop.toASN1();
    if( controls != null && controls.length > 0) {
      _controls = new ASN1Sequence();
      controls.forEach((control) {
        _controls.add( control.toASN1());
        logger.finest("adding control $control");
      });
    }

    String toString() =>
        "LDAPMessage(id=$_messageId $protocolOp controls=$_controls";

  }


  LDAPMessage.fromBytes(Uint8List bytes) {
    var o = new ASN1Sequence.fromBytes(bytes);

    checkCondition(o !=null,"Parsing error on ${bytes}");
    checkCondition( o.elements.length == 2 || o.elements.length == 3, "Expecting two or three elements.actual = ${o.elements.length} obj=$o");


    var i = o.elements[0] as ASN1Integer;
    _messageId = i.intValue;

    _protocolOp = o.elements[1] as ASN1Sequence;

    _protocolTag = _protocolOp.tag;

    // optional - message has controls....
    if( o.elements.length == 3) {
      logger.finest("Controls = ${o.elements[2]} ${o.elements[2].encodedBytes}");
      // todo: Get rid of this hack
      // See http://stackoverflow.com/questions/15035349/how-does-0-and-3-work-in-asn1
      // The control sequeunce is encoded with a tag of 0xA0 - which is a context specific encoding
      var c = o.elements[2].encodedBytes;
      c[0] = 0x10; // wack the tag and set it to a sequence
      var c2 = new ASN1Sequence.fromBytes(c);

      //_controls = o.elements[2];
      _controls = c2;
    }


    _obj = o; // save this?
    logger.fine("Got LDAP Message. Id = ${messageId} protocolOp = ${protocolOp}");

  }


  // Convert this LDAP message to a stream of ASN1 encoded bytes
  List<int> toBytes() {

    //logger.finest("Converting this object to bytes ${toString()}");
    ASN1Sequence seq = new ASN1Sequence();

    seq.add( new ASN1Integer(_messageId));

    seq.add(_obj);
    if( _controls != null)
      seq.add(_controls);

    var b = seq.encodedBytes;

    var xx = LDAPUtil.toHexString(b);
    logger.finest("LdapMesssage bytes = ${xx}");
    return b;

  }

  String toString() {
    var s = _op2String(_protocolTag);
    return "Msg(id=${_messageId}, op=${s},controls=$_controls)";
  }

}
