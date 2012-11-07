part of ldap_protocol;

class SearchRequest extends RequestOp {
  
  String _baseDN; 
  int _scope ;
  int _sizeLimit; 
  int _derefPolicy = 0;
  List<String> _attributes;
  bool _typesOnly  = false;
  int _timeLimit = 10000;
  
  String _filter; // string for now....
  
  SearchRequest(this._baseDN, this._filter, this._attributes, [this._scope = SearchScope.SUB_LEVEL, this._sizeLimit = 1000]) {
    _protocolOp = SEARCH_REQUEST; 
  }
  
  ASN1Sequence toASN1Sequence() {  
    var seq = _startSequence();
    
    seq..add(new ASN1OctetString(_baseDN))
        ..add(new ASN1Enumerated(_scope))
        ..add(new ASN1Enumerated(_derefPolicy))
        ..add(new ASN1Integer(_sizeLimit))
        ..add(new ASN1Integer(_timeLimit))
        ..add(new ASN1Boolean(_typesOnly))
        ..add(new ASN1OctetString(_filter));
   
    return seq;   
  }
  
}
