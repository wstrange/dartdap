part of ldap_protocol;


class SearchResultEntry extends ProtocolOp {
  
  String _dn;
  
  String get dn => _dn;
  
  List<Attribute> _attributes = new List();
  
  SearchResultEntry(ASN1Sequence s): super(s.tag) {
    //_protocolOp = s.tag;
        
    // element[0] - dn
    
    var t = s.elements[0] as ASN1OctetString;
    
    _dn = t.stringValue;
    
    logger.finest("Search Entry dn=${dn}");
    
    // embedded sequence is attr list
    var seq = s.elements[1] as ASN1Sequence;
    
    seq.elements.forEach( (ASN1Sequence attr)  {
      var attrName = attr.elements[0] as ASN1OctetString;
    
      var vals = attr.elements[1] as ASN1Set;
      _attributes.add( new Attribute.fromASN1(attrName,vals));
    });
    
    // controls are optional.
    if( s.elements.length >= 3) {
      var controls = s.elements[2];
      logger.finest( "Controls = ${controls}");
    }
    
  }
  
  String toString() {
    return "SearchEntry(${_dn}, ${_attributes})";
  }
}
