part of ldap_protocol;


class Filter {
  
  int _filterType;

  // The assertion value for this filter.
  ASN1OctetString _assertionValue;
  String _attributeName;
  

  /** 
   * BER types 
   */
  const int FILTER_TYPE_AND =  0xA0;
  const int FILTER_TYPE_OR =   0xA1;
  const int FILTER_TYPE_NOT =  0xA2;
  const int FILTER_TYPE_EQUALITY =  0xA3;
  const int FILTER_TYPE_SUBSTRING =  0xA4;
  const int FILTER_TYPE_GREATER_OR_EQUAL =  0xA5;
  const int FILTER_TYPE_LESS_OR_EQUAL =  0xA6;
  const int FILTER_TYPE_PRESENCE =  0x87;
  const int FILTER_TYPE_APPROXIMATE_MATCH =  0xA8;
  const int FILTER_TYPE_EXTENSIBLE_MATCH =  0xA9;
  const int SUBSTRING_TYPE_SUBINITIAL =  0x80;
  const int SUBSTRING_TYPE_SUBANY =  0x81;
  const int SUBSTRING_TYPE_SUBFINAL =  0x82;
  const int EXTENSIBLE_TYPE_MATCHING_RULE_ID =  0x81;
  const int EXTENSIBLE_TYPE_ATTRIBUTE_NAME =  0x82;
  const int EXTENSIBLE_TYPE_MATCH_VALUE =  0x83;
  const int EXTENSIBLE_TYPE_DN_ATTRIBUTES =  0x84;
  

  Filter.equalityFilter(this._attributeName,  String attrValue) {
    _filterType = FILTER_TYPE_EQUALITY;
    _assertionValue = new ASN1OctetString(attrValue);   
  }
  
  ASN1Sequence toASN1Sequence() {
    
    var seq= new ASN1Sequence(_filterType);
    switch (_filterType)
    {
      case FILTER_TYPE_EQUALITY:
      case FILTER_TYPE_GREATER_OR_EQUAL:
      case FILTER_TYPE_LESS_OR_EQUAL:
      case FILTER_TYPE_APPROXIMATE_MATCH:
        seq.add(new ASN1OctetString(_attributeName));
        seq.add(_assertionValue);
        break; 
    }
    return seq;
    
  }
    
}



