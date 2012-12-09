library filter;
import 'package:asn1lib/asn1lib.dart';
import 'package:logging/logging.dart';


import 'ldap_exception.dart';
import 'ldap_util.dart';


/**
 * Represents an LDAP search filter
 */

class Filter {

  int _filterType;

  int get filterType => _filterType;

  // The assertion value for this filter.
  String _assertionValue;
  String get assertionValue => _assertionValue;
  String _attributeName;
  String get attributeName => _attributeName;

  // nested filters
  List<Filter> _subFilters = new List<Filter>();
  List<Filter> get  subFilters => _subFilters;

  /**
   * BER types
   */
  static const int TYPE_AND =  0xA0;
  static const int TYPE_OR =   0xA1;
  static const int TYPE_NOT =  0xA2;
  static const int TYPE_EQUALITY =  0xA3;
  static const int TYPE_SUBSTRING =  0xA4;
  static const int TYPE_GREATER_OR_EQUAL =  0xA5;
  static const int TYPE_LESS_OR_EQUAL =  0xA6;

  // correct??? should it be 0xA7 or 0x87???
  //static const int TYPE_PRESENCE =  0x87;
  static const int TYPE_PRESENCE =  0xA7;

  static const int TYPE_APPROXIMATE_MATCH =  0xA8;
  static const int TYPE_EXTENSIBLE_MATCH =  0xA9;


  static const int EXTENSIBLE_TYPE_MATCHING_RULE_ID =  0x81;
  static const int EXTENSIBLE_TYPE_ATTRIBUTE_NAME =  0x82;
  static const int EXTENSIBLE_TYPE_MATCH_VALUE =  0x83;
  static const int EXTENSIBLE_TYPE_DN_ATTRIBUTES =  0x84;


  Filter(this._filterType,[this._attributeName,
                           this._assertionValue,this._subFilters]);

  static Filter equals(String attributeName,  String attrValue) =>
      new Filter(TYPE_EQUALITY,attributeName,attrValue);


  static Filter and(List<Filter> filters) =>
      new Filter(TYPE_AND,null,null,filters);


  static Filter or(List<Filter> filters) =>
      new Filter(TYPE_OR,null,null,filters);


  static Filter not(Filter f) => new Filter(TYPE_NOT,null,null,[f]);

  static Filter present(String attrName) =>
      new Filter(TYPE_PRESENCE,attrName);


  static Filter substring(String pattern) => new SubstringFilter(pattern);


  Filter operator&(Filter other) => Filter.and([this,other]);
  Filter operator|(Filter other) => Filter.or([this,other]);

  String toString() =>
      "Filter(type=$_filterType attrName=$_attributeName val=$_assertionValue, subFilters=$_subFilters)";

}

/**
 * A Substring filter
 * Clients should not need to invoke this directly. Use [Filter.substring()]
 */
class SubstringFilter extends Filter {
  /// BER type for initial part of string filter
  static const int TYPE_SUBINITIAL =  0x80;
  /// BER type for any part of string filter
  static const int TYPE_SUBANY =  0x81;
  /// BER type for final part of string filter
  static const int TYPE_SUBFINAL =  0x82;

  String _initial;
  List<String> _any = [];
  String _final;


  /** The initial substring filter component. Zero or one */
  String get initial => _initial;
  /** The list of "any" components. Zero or more */
  List<String> get any => _any;
  /** The final component. Zero or more */
  String get finalString => _final;


  SubstringFilter(String pattern) : super(Filter.TYPE_SUBSTRING)  {

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
      _initial =  x[0];
    if( x.last != "")
      _final = x.last;
    for(int i = 1; i < x.length -1 ; ++i) {
      _any.add(x[i]);
    }
  }


  String toString() =>
      "SubstringFilter(_init=$_initial, any=$_any, fin=$_final)";

}

