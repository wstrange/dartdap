part of ldap_protocol;

/*

  SearchRequest ::= [APPLICATION 3] SEQUENCE {
             baseObject      LDAPDN,
             scope           ENUMERATED {
                  baseObject              (0),
                  singleLevel             (1),
                  wholeSubtree            (2),
                  ...  },
             derefAliases    ENUMERATED {
                  neverDerefAliases       (0),
                  derefInSearching        (1),
                  derefFindingBaseObj     (2),
                  derefAlways             (3) },
             sizeLimit       INTEGER (0 ..  maxInt),
             timeLimit       INTEGER (0 ..  maxInt),
             typesOnly       BOOLEAN,
             filter          Filter,
             attributes      AttributeSelection }

        AttributeSelection ::= SEQUENCE OF selector LDAPString
                        -- The LDAPString is constrained to
                        -- <attributeSelector> in Section 4.5.1.8

 */
class SearchRequest extends RequestOp {
  String _baseDN;
  int _scope;
  int _sizeLimit;
  //int _derefPolicy = 3; // todo: read spec on this
  int _derefPolicy = 0; // todo: read spec on this

  List<String> _attributes;
  bool _typesOnly = false;
  int _timeLimit = 0; // default: no time limit

  Filter _filter;

  // todo: These should be named params
  SearchRequest(this._baseDN, this._filter, this._attributes,
      [this._scope = SearchScope.SUB_LEVEL, this._sizeLimit = 0])
      : super(SEARCH_REQUEST);

  ASN1Object toASN1() {
    var seq = _startSequence();

    var attrSet = new ASN1Sequence();
    _attributes.forEach((String attr) {
      attrSet.add(new ASN1OctetString(attr));
    });

    seq
      ..add(new ASN1OctetString(_baseDN))
      ..add(new ASN1Enumerated(_scope))
      ..add(new ASN1Enumerated(_derefPolicy))
      ..add(ASN1Integer.fromInt(_sizeLimit))
      ..add(ASN1Integer.fromInt(_timeLimit))
      ..add(new ASN1Boolean(_typesOnly))
      ..add(_filter.toASN1())
      ..add(attrSet);

    return seq;
  }
}
