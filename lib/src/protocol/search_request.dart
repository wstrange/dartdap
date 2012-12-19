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
        ..add(_filterToASN1(_filter))
        ..add(attrSet);


    return seq;
  }

  /**
   * Convert a Filter expression to ASN1 Object
   *
   * This may be called recursively
   */
  ASN1Object _filterToASN1(Filter f) {
    switch (f.filterType)
    {
      case Filter.TYPE_EQUALITY:
      case Filter.TYPE_GREATER_OR_EQUAL:
      case Filter.TYPE_LESS_OR_EQUAL:
      case Filter.TYPE_APPROXIMATE_MATCH:
        var seq= new ASN1Sequence(f.filterType);
        seq.add(new ASN1OctetString(f.attributeName));
        seq.add(new ASN1OctetString(LDAPUtil.escapeString(f.assertionValue)));
        return seq;

      case Filter.TYPE_AND:
      case Filter.TYPE_OR:
        var aset = new ASN1Set(f.filterType);
        f.subFilters.forEach( (Filter subf) {
          aset.add(_filterToASN1(subf));
        });
        return aset;


      case Filter.TYPE_PRESENCE:
        var s = new ASN1OctetString(f.attributeName);
        s.tag = f.filterType; // have to explicity set tag to override
        return s;

      case Filter.TYPE_NOT:
        // encoded as
        // tag=NOT, length bytes, filter bytes....

        assert(f.subFilters != null);
        var notObj = f.subFilters[0];
        assert(notObj != null);

        // todo: we need to force encoding to get the bytes.
        // why?? Should we change asn1object?
        // or create a ASN1Wrapper object
        var enc = _filterToASN1(notObj);
        enc.encode();
        var xx = LDAPUtil.toHexString(enc.encodedBytes);
        print("******* NOT encoded bytes = $xx");

        var foo = new ASN1Object.fromTag(Filter.TYPE_NOT,
            enc.encodedBytes);
        print("Foo= $foo, bytes = ${foo.encodedBytes}");
        return new ASN1Object.fromTag(Filter.TYPE_NOT,
            enc.encodedBytes);



      case Filter.TYPE_SUBSTRING:
        var s = f as SubstringFilter;
        var seq = new ASN1Sequence(s.filterType);
        seq.add(new ASN1OctetString(s.attributeName));
        // sub sequence embeds init,any,final
        var sSeq = new ASN1Sequence();

        if( s.initial != null)
          sSeq.add(new ASN1OctetString.withTag(SubstringFilter.TYPE_SUBINITIAL,s.initial));
        s.any.forEach( (String o) => sSeq.add(new ASN1OctetString.withTag(SubstringFilter.TYPE_SUBANY,o)));
        if( s.finalString != null )
          sSeq.add(new ASN1OctetString.withTag(SubstringFilter.TYPE_SUBFINAL,s.finalString));

        seq.add(sSeq);
        return seq;

      case Filter.TYPE_EXTENSIBLE_MATCH:
        throw "Not Done yet. Fix me!!";

      default:
        throw new LDAPException(
            "Unexpected filter type = $f.filterType. This should never happen");

    }
  }

}

/*  todo
 *
      case TYPE_EXTENSIBLE_MATCH:
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
 *
 */

