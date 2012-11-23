part of ldap_protocol;

class SearchRequest extends RequestOp {
  
  String _baseDN; 
  int _scope ;
  int _sizeLimit; 
  int _derefPolicy = 0;
  List<String> _attributes;
  bool _typesOnly  = false;
  int _timeLimit = 10000;
  
  Filter _filter; 
  
  
  SearchRequest(this._baseDN, this._filter, this._attributes, [this._scope = SearchScope.SUB_LEVEL, this._sizeLimit = 1000]):
    super(SEARCH_REQUEST) {
//    /_protocolOp = SEARCH_REQUEST; 
  }
  
  ASN1Sequence toASN1Sequence() {  
    var seq = _startSequence();
    
    var attrSet  = new ASN1Sequence();
    _attributes.forEach((String attr) { attrSet.add(new ASN1OctetString(attr));});
    
    
    seq..add(new ASN1OctetString(_baseDN))
        ..add(new ASN1Enumerated(_scope))
        ..add(new ASN1Enumerated(_derefPolicy))
        ..add(new ASN1Integer(_sizeLimit))
        ..add(new ASN1Integer(_timeLimit))
        ..add(new ASN1Boolean(_typesOnly))
        ..add(_filter.toASN1())
        ..add(attrSet);
    
    
   
    return seq;   
  }
  
}
