part of ldap_protocol;


class ResponseHandler {
  LDAPMessage _ldapMessage;
  
  ResponseHandler(this._ldapMessage);
  
  static ResponseOp handleResponse(LDAPMessage m) {
 
    var p = m.protocolOp;
    logger.finest("handle response tag=${_op2String(p.tag)}");
    //var o = seq.elements[1];
    
    ProtocolOp op;
    switch(p.tag) {
      case BIND_RESPONSE:
        op = new BindResponse(p);
        break;
      
      case SEARCH_RESULT_ENTRY:
        op = new SearchEntryResponse(p);
        break;
        
      case EXTENDED_RESPONSE:
         logger.severe("Extended response. ");
         throw "not done";
         //break;
        
        
      default: 
        throw "Not done";
    }
    return op;
    
  }
  
  
}
