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
  
  ASN1Sequence _obj;
  
  int get messageId => _messageId;
  
  ASN1Sequence get protocolOp => _protocolOp;
  
  int get messageLength => _obj.totalEncodedByteLength;
  
  
  LDAPMessage(this._messageId,RequestOp rop) {
    _protocolTag = rop.protocolOpCode;
    _obj = rop.toASN1Sequence();
  }
  
  
  LDAPMessage.fromBytes(Uint8List bytes) {
    _obj = new ASN1Sequence.fromBytes(bytes);
    
    if( _obj  == null || _obj.elements.length < 2 || _obj.elements.length > 3) 
      throw new LDAPException("LDAP Message unexpected format. Bytes =${bytes}");
    
    
    var i = _obj.elements[0] as ASN1Integer;
    _messageId = i.intValue;
    
    _protocolOp = _obj.elements[1] as ASN1Sequence;
    // optional - controls....
    _protocolTag = _protocolOp.tag;
    
    if( _obj.elements.length == 3)
      _controls = _obj.elements[3] as ASN1Sequence;
    
    
    logger.fine("Got LDAP Message. Id = ${messageId} protocolOp = ${protocolOp}");
    
  }

  
 
  List<int> toBytes() {

    ASN1Sequence seq = new ASN1Sequence();
    
    seq.add( new ASN1Integer(_messageId));
    
    seq.add(_obj);
    
    seq.encode();
    var b = seq.encodedBytes;
    
    logger.fine("LdapMesssage bytes = ${b}");
    return b;
    
  }
  
  String toString() {
    var s = _op2String(_protocolTag);
    return "Msg(id=${_messageId}, op=${s})";
  }
  
}
