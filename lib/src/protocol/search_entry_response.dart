part of ldap_protocol;


class SearchEntryResponse extends ProtocolOp {
  
  String _dn;
  
  String get dn => _dn;
  
  SearchEntryResponse(ASN1Sequence s) {
    _protocolOp = s.tag;
        
    // element[0] - dn
    
    var t = s.elements[0] as ASN1OctetString;
    
    _dn = t.stringValue;
    
    logger.finest("Search Entry dn=${dn}");
    
    // embedded sequence is attr list
    var seq = s.elements[1] as ASN1Sequence;
    
    seq.elements.forEach( (ASN1Sequence attr)  {
      var attrName = attr.elements[0] as ASN1OctetString;
      var xx = attrName.stringValue;
      logger.finest("search attr = ${xx}" );
      
      //var valList = xx.elements[1];
          
    });
    
    // controls are optional.
    
    
    
  }
}
