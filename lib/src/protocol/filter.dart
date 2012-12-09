part of ldap_protocol;


/**
 * Represents an LDAP search filter
 */

class Filter {
  
  int _filterType;

  // The assertion value for this filter.
  String _assertionValue;
  String _attributeName;
  
  // nested filters
  List<Filter> _subFilters = new List<Filter>();
  

  /** 
   * BER types 
   */
  static const int _FILTER_TYPE_AND =  0xA0;
  static const int _FILTER_TYPE_OR =   0xA1;
  static const int _FILTER_TYPE_NOT =  0xA2;
  static const int _FILTER_TYPE_EQUALITY =  0xA3;
  static const int _FILTER_TYPE_SUBSTRING =  0xA4;
  static const int _FILTER_TYPE_GREATER_OR_EQUAL =  0xA5;
  static const int _FILTER_TYPE_LESS_OR_EQUAL =  0xA6;
  
  // correct??? should it be 0xA7 or 0x87???
  //static const int _FILTER_TYPE_PRESENCE =  0x87;
  static const int _FILTER_TYPE_PRESENCE =  0xA7;
  
  static const int _FILTER_TYPE_APPROXIMATE_MATCH =  0xA8;
  static const int _FILTER_TYPE_EXTENSIBLE_MATCH =  0xA9;
  
  
  
  static const int _EXTENSIBLE_TYPE_MATCHING_RULE_ID =  0x81;
  static const int _EXTENSIBLE_TYPE_ATTRIBUTE_NAME =  0x82;
  static const int _EXTENSIBLE_TYPE_MATCH_VALUE =  0x83;
  static const int _EXTENSIBLE_TYPE_DN_ATTRIBUTES =  0x84;
  
  
  Filter(this._filterType,[this._attributeName, 
                           this._assertionValue,this._subFilters]);

  static Filter equals(String attributeName,  String attrValue) =>  
      new Filter(_FILTER_TYPE_EQUALITY,attributeName,attrValue);
   
  
  static Filter and(List<Filter> filters) => 
      new Filter(_FILTER_TYPE_AND,null,null,filters);
    
  
  static Filter or(List<Filter> filters) => 
      new Filter(_FILTER_TYPE_OR,null,null,filters);
  
  
  static Filter not(Filter f) => new Filter(_FILTER_TYPE_NOT,null,null,[f]);   
  
  static Filter present(String attrName) => 
      new Filter(_FILTER_TYPE_PRESENCE,attrName);
  
  
  static Filter substring(String pattern) => new SubstringFilter(pattern);
 
  
  Filter operator&(Filter other) => Filter.and([this,other]);  
  Filter operator|(Filter other) => Filter.or([this,other]);
  
  ASN1Object toASN1() {
    switch (_filterType)
    {
      case _FILTER_TYPE_EQUALITY:
      case _FILTER_TYPE_GREATER_OR_EQUAL:
      case _FILTER_TYPE_LESS_OR_EQUAL:
      case _FILTER_TYPE_APPROXIMATE_MATCH:
        var seq= new ASN1Sequence(_filterType);
        var s = new ASN1OctetString(LDAPUtil.escapeString(_assertionValue));
        seq.add(new ASN1OctetString(_attributeName));
        seq.add(s);
        return seq;
        
      case _FILTER_TYPE_AND:
      case _FILTER_TYPE_OR:
        var aset = new ASN1Set(_filterType);
        _subFilters.forEach( (Filter f) {
          aset.add(f.toASN1());
        });
        return aset;
     
        
      case _FILTER_TYPE_PRESENCE:
        var s = new ASN1OctetString(_attributeName);
        s.tag = _filterType; // have to explicity set tag 
        return s;
        
      case _FILTER_TYPE_NOT: 
        // encoded as   
        // tag=NOT, length bytes, filter bytes....
        
        assert(_subFilters != null);
        var notObj = _subFilters[0];
        assert(notObj != null);
        return new ASN1Object.fromTag(_FILTER_TYPE_NOT,
            notObj.toASN1().encodedBytes);
    
      // This should never happen we implment this in the subclass  
      //case _FILTER_TYPE_SUBSTRING: 
      //  return this.toASN1();
        
      case _FILTER_TYPE_EXTENSIBLE_MATCH:
        throw "Not Done yet. Fix me!!";
        
      default: 
        throw new LDAPException(
            "Unexpected filter type = $_filterType. This should never happen");
        
    }
  }
  
  /**
   *  public ASN1Element encode()
  {
    switch (filterType)
    {
      case _FILTER_TYPE_AND:
      case _FILTER_TYPE_OR:
        final ASN1Element[] filterElements =
             new ASN1Element[filterComps.length];
        for (int i=0; i < filterComps.length; i++)
        {
          filterElements[i] = filterComps[i].encode();
        }
        return new ASN1Set(filterType, filterElements);


      case _FILTER_TYPE_NOT:
        return new ASN1Element(filterType, notComp.encode().encode());


      case _FILTER_TYPE_EQUALITY:
      case _FILTER_TYPE_GREATER_OR_EQUAL:
      case _FILTER_TYPE_LESS_OR_EQUAL:
      case _FILTER_TYPE_APPROXIMATE_MATCH:
        final ASN1OctetString[] attrValueAssertionElements =
        {
          new ASN1OctetString(attrName),
          assertionValue
        };
        return new ASN1Sequence(filterType, attrValueAssertionElements);


      case _FILTER_TYPE_SUBSTRING:
        final ArrayList<ASN1OctetString> subList =
             new ArrayList<ASN1OctetString>(2 + subAny.length);
        if (subInitial != null)
        {
          subList.add(new ASN1OctetString(SUBSTRING_TYPE_SUBINITIAL,
                                          subInitial.getValue()));
        }

        for (final ASN1Element subAnyElement : subAny)
        {
          subList.add(new ASN1OctetString(SUBSTRING_TYPE_SUBANY,
                                          subAnyElement.getValue()));
        }


        if (subFinal != null)
        {
          subList.add(new ASN1OctetString(SUBSTRING_TYPE_SUBFINAL,
                                          subFinal.getValue()));
        }

        final ASN1Element[] subFilterElements =
        {
          new ASN1OctetString(attrName),
          new ASN1Sequence(subList)
        };
        return new ASN1Sequence(filterType, subFilterElements);


      case _FILTER_TYPE_PRESENCE:
        return new ASN1OctetString(filterType, attrName);


      case _FILTER_TYPE_EXTENSIBLE_MATCH:
        final ArrayList<ASN1Element> emElementList =
             new ArrayList<ASN1Element>(4);
        if (matchingRuleID != null)
        {
          emElementList.add(new ASN1OctetString(
               EXTENSIBLE_TYPE_MATCHING_RULE_ID, matchingRuleID));
        }

        if (attrName != null)
        {
          emElementList.add(new ASN1OctetString(
               EXTENSIBLE_TYPE_ATTRIBUTE_NAME, attrName));
        }

        emElementList.add(new ASN1OctetString(EXTENSIBLE_TYPE_MATCH_VALUE,
                                              assertionValue.getValue()));

        if (dnAttributes)
        {
          emElementList.add(new ASN1Boolean(EXTENSIBLE_TYPE_DN_ATTRIBUTES,
                                            true));
        }

        return new ASN1Sequence(filterType, emElementList);


      default:
        throw new AssertionError(ERR_FILTER_INVALID_TYPE.get(
                                      toHex(filterType)));
    }
  }
  */
  
  String toString() => 
      "Filter(type=$_filterType attrName=$_attributeName val=$_assertionValue, subFilters=$_subFilters)";
    
}

/**
 * A Substring filter
 * Clients should not need to invoke this directly. Use [Filter.substring()]
 */
class SubstringFilter extends Filter { 
  static const int _SUBSTRING_TYPE_SUBINITIAL =  0x80;
  static const int _SUBSTRING_TYPE_SUBANY =  0x81;
  static const int _SUBSTRING_TYPE_SUBFINAL =  0x82;
  
  ASN1OctetString _initial;
  List<ASN1OctetString> _any = [];
  ASN1OctetString _final;
  
  // The getters are really only needed for testing..
  // can we replace them???
  /** The initial substring filter component. Zero or one */
  ASN1OctetString get initial => _initial;
  /** The list of "any" components. Zero or more */
  List<ASN1OctetString> get any => _any;
  /** The final component. Zero or more */
  ASN1OctetString get finalStr => _final;
  

  SubstringFilter(String pattern) : super(Filter._FILTER_TYPE_SUBSTRING)  {
    
    // todo: We probaby need to properly escape special chars = and *
    var l = pattern.split("=");
    if(l.length != 2 || l[0] == "" || l[1] == "") 
      throw new LDAPException("Invalid substring search pattern '$pattern'");
    
    _attributeName = l[0];
    var matchString = l[1];
    
    // now parse initial, any, final
    
    var x = matchString.split("*");
    // must be at least one * -giving a split of at least two strings
    assert(x.length > 1);

    /*
     *  foo*   
     *  *foo
     *  
     *  foo*bar
     *  foo*bar*baz*boo
     */
    
    if( x[0] != "") 
      _initial =  new ASN1OctetString.withTag(_SUBSTRING_TYPE_SUBINITIAL,x[0]);
    if( x.last != "") 
      _final =new ASN1OctetString.withTag(_SUBSTRING_TYPE_SUBFINAL,x.last);
    for(int i = 1; i < x.length -1 ; ++i) {
      _any.add(new ASN1OctetString.withTag(_SUBSTRING_TYPE_SUBANY,x[i]));
    }
  }
  
  /**
   * Create ASN1 representation by encoding intial, any and final components
   * of the search string
   */
  ASN1Object toASN1() {
    var seq = new ASN1Sequence(_filterType);
    seq.add(new ASN1OctetString(_attributeName));
    // sub sequence embeds init,any,final
    var sSeq = new ASN1Sequence();
    
    if( _initial != null) 
      sSeq.add(_initial);
    _any.forEach( (ASN1Object o) => sSeq.add(o));
    if( _final != null ) 
      sSeq.add(_final);

    seq.add(sSeq);
    return seq;
  }
  
  String toString() =>
      "SubstringFilter(_init=$_initial, any=$_any, fin=$_final)";

}

