import 'package:asn1lib/asn1lib.dart';
import 'package:collection/collection.dart';
import 'ldap_util.dart';
import 'ldap_exception.dart';

/// An LDAP search filter.
///
/// An LDAP search filter can be a single filter created using either of these
/// factory methods:
///
/// * [present] - matches if the entry contains the attribute
/// * [equals] - matches if an attribute has a given value
/// * [substring] - matches wildcard
/// * [approx] - matches if an attribute approximately has the value
/// * [greaterOrEquals] - matches if the value is greater than or equal
/// * [lessOrEquals] - matches if the entry has the attribute with a value that is less than or equal to the supplied value
///
/// Or it can be a compound filter that composes other filters created using
/// these factory methods:
///
/// * [not] - matches if its member filter does not match
/// * [and] - matches if all of its member filters match
/// * [or] - matches if at least one of its member filters match

class Filter {
  final int _filterType;
  int get filterType => _filterType;

  // The assertion value for this filter.
  final String? _assertionValue;
  String? get assertionValue => _assertionValue;
  String? _attributeName;
  String? get attributeName => _attributeName;

  // nested filters
  late final List<Filter> _subFilters;
  List<Filter> get subFilters => _subFilters;

  // BER Types
  static const int TYPE_AND = 0xA0;
  static const int TYPE_OR = 0xA1;
  static const int TYPE_NOT = 0xA2;
  static const int TYPE_EQUALITY = 0xA3;
  static const int TYPE_SUBSTRING = 0xA4;
  static const int TYPE_GREATER_OR_EQUAL = 0xA5;
  static const int TYPE_LESS_OR_EQUAL = 0xA6;

  static const int TYPE_PRESENCE = 0x87;
  static const int TYPE_APPROXIMATE_MATCH = 0xA8;
  static const int TYPE_EXTENSIBLE_MATCH = 0xA9;

  static const int EXTENSIBLE_TYPE_MATCHING_RULE_ID = 0x81;
  static const int EXTENSIBLE_TYPE_ATTRIBUTE_NAME = 0x82;
  static const int EXTENSIBLE_TYPE_MATCH_VALUE = 0x83;
  static const int EXTENSIBLE_TYPE_DN_ATTRIBUTES = 0x84;

  /// Constructor
  ///
  /// It is preferable to use one of the convenience methods ([present],
  /// [equals], [substring], [approx], [greaterOrEquals], [lessOrEquals])
  /// instead of directly using this constructor.

  Filter(this._filterType,
      [this._attributeName, this._assertionValue, this._subFilters = const []]);

  /// Creates a [Filter] that matches an entry that has an attribute with the given value.
  static Filter equals(String attributeName, String attrValue) =>
      Filter(TYPE_EQUALITY, attributeName, attrValue);

  /// Creates a [Filter] that matches entries that matches all of the [filters].
  static Filter and(List<Filter> filters) =>
      Filter(TYPE_AND, null, null, filters);

  /// Creates a [Filter] that matches entries that matches at least one of the [filters].
  static Filter or(List<Filter> filters) =>
      Filter(TYPE_OR, null, null, filters);

  /// Creates a [Filter] that matches entries that don't match on [f].
  static Filter not(Filter f) => Filter(TYPE_NOT, null, null, [f]);

  /// Creates a [Filter] that matches an entry contains an attribute.
  static Filter present(String attrName) => Filter(TYPE_PRESENCE, attrName);

  /// Creates a [Filter] that matches on a substring.
  ///
  /// The [pattern] must be a [String] of the form 'attr=match', where _attr_ is
  /// the attribute name and _match_ is a value that has at least one `*`
  /// character. There can be wildcard `*` chararcters at the beginning, middle
  /// or end of _match_.
  ///
  /// The _match_ must not be a single `*` (e.g. 'foo=*' is not permitted). If
  /// such a filter is required, use the [present] filter instead.

  static Filter substring(String attribute, String pattern) =>
      SubstringFilter.fromPattern(attribute, pattern);

  /// Creates a [Filter] that matches an entry that contains the [attributeName]
  /// with a value that is greater than or equal to [attrValue].
  static Filter greaterOrEquals(String attributeName, String attrValue) =>
      Filter(TYPE_GREATER_OR_EQUAL, attributeName, attrValue);

  /// Creates a [Filter] that matches an entry that contains the [attributeName]
  /// with a value that is less than or equal to [attrValue].
  static Filter lessOrEquals(String attributeName, String attrValue) =>
      Filter(TYPE_LESS_OR_EQUAL, attributeName, attrValue);

  /// Creates a [Filter] that matches an entry that contains the [attributeName]
  /// that approximately matches [attrValue].
  static Filter approx(String attributeName, String attrValue) =>
      Filter(TYPE_APPROXIMATE_MATCH, attributeName, attrValue);

  /// Operator version of the [and] filter factory method.
  Filter operator &(Filter other) => Filter.and([this, other]);

  /// Operator version of the [or] filter factory method.
  Filter operator |(Filter other) => Filter.or([this, other]);

  @override
  String toString() {
    var s = 'Filter(type=0x${_filterType.toRadixString(16)}';
    if (_attributeName != null) s += ',attributeName=$_attributeName';
    if (_assertionValue != null) s += ',value=$_assertionValue,';
    s += _subFilters.toString();
    s += ')';
    return s;
  }

  /// Convert a Filter expression to an ASN1 Object
  /// This may be called recursively
  ASN1Object toASN1() {
    switch (filterType) {
      case Filter.TYPE_EQUALITY:
      case Filter.TYPE_GREATER_OR_EQUAL:
      case Filter.TYPE_LESS_OR_EQUAL:
      case Filter.TYPE_APPROXIMATE_MATCH:
        var seq = ASN1Sequence(tag: filterType);
        seq.add(ASN1OctetString(attributeName));
        seq.add(ASN1OctetString(LdapUtil.escapeString(assertionValue!)));
        return seq;

      case Filter.TYPE_AND:
      case Filter.TYPE_OR:
        assert(subFilters.isNotEmpty);
        var aset = ASN1Set(tag: filterType);
        subFilters.forEach((Filter subf) {
          aset.add(subf.toASN1());
        });
        return aset;

      case Filter.TYPE_PRESENCE:
        return ASN1OctetString(attributeName, tag: filterType);

      case Filter.TYPE_NOT:
        // like AND/OR but with only one subFilter.
        assert(subFilters.isNotEmpty);
        var notObj = ASN1Set(tag: filterType);
        notObj.add(subFilters[0].toASN1());
        return notObj;

      case Filter.TYPE_EXTENSIBLE_MATCH:
        throw 'Not Done yet. Fix me!!';

      default:
        throw LdapUsageException(
            'Unexpected filter type = $filterType. This should never happen');
    }
  }

  final Function _eq = const ListEquality().equals;

  @override
  bool operator ==(other) =>
      other is Filter &&
      other._filterType == _filterType &&
      other._assertionValue == _assertionValue &&
      other._attributeName == _attributeName &&
      _eq(other._subFilters, _subFilters);

  @override
  int get hashCode =>
      _filterType.hashCode ^
      _assertionValue.hashCode ^
      _attributeName.hashCode ^
      _subFilters.hashCode ^
      _eq.hashCode;
}

/// A Substring filter
/// Clients should not need to invoke this directly. Use [Filter.substring()]
class SubstringFilter extends Filter {
  /// BER type for initial part of string filter
  static const int TYPE_SUBINITIAL = 0x80;

  /// BER type for any part of string filter
  static const int TYPE_SUBANY = 0x81;

  /// BER type for final part of string filter
  static const int TYPE_SUBFINAL = 0x82;

  String? _initial;
  List<String> _any;
  String? _final;

  /// The initial substring filter component. Zero or one
  String? get initial => _initial;

  /// The list of 'any' components. Zero or more
  List<String> get any => _any;

  /// The final component. Zero or more */
  String? get finalString => _final;

  SubstringFilter.rfc224(String attributeName,
      {String? initial, List<String> any = const [], String? finalValue})
      : _initial = initial,
        _any = any,
        _final = finalValue,
        super(Filter.TYPE_SUBSTRING) {
    _attributeName = attributeName;
  }

  SubstringFilter.fromPattern(String attributeName, String pattern)
      : _any = const [],
        super(Filter.TYPE_SUBSTRING) {
    // todo: We probaby need to properly escape special chars = and *
    if (pattern.length <= 2 || !pattern.contains('*')) {
      throw LdapUsageException(
          'Invalid substring pattern: expecting attr=match: $pattern');
    }

    _attributeName = attributeName;
    // now parse initial, any, final

    var x = pattern.split('*');

    if (x.length == 1) {
      throw LdapUsageException(
          'Invalid substring pattern: missing *: $pattern');
    }

    if (!x.any((s) => s.isNotEmpty)) {
      throw LdapUsageException(
          'Invalid substring pattern: use \'present\' filter instead: \'$pattern\'');
    }

    /*
     *  foo*
     *  *foo
     *
     *  foo*bar
     *  foo*bar*baz*boo
     */

    if (x[0] != '') {
      _initial = x[0];
    }
    if (x.last != '') {
      _final = x.last;
    }
    _any = [];
    for (var i = 1; i < x.length - 1; ++i) {
      _any.add(x[i]);
    }
  }

  @override
  ASN1Object toASN1() {
    var seq = ASN1Sequence(tag: filterType);
    seq.add(ASN1OctetString(attributeName));
    // sub sequence embeds init,any,final
    var sSeq = ASN1Sequence();

    if (_initial != null) {
      sSeq.add(ASN1OctetString(initial, tag: SubstringFilter.TYPE_SUBINITIAL));
    }
    if (any.isNotEmpty) {
      any.forEach((v) =>
          sSeq.add(ASN1OctetString(v, tag: SubstringFilter.TYPE_SUBANY)));
    }
    if (_final != null) {
      sSeq.add(
          ASN1OctetString(finalString, tag: SubstringFilter.TYPE_SUBFINAL));
    }
    seq.add(sSeq);
    return seq;
  }

  @override
  String toString() =>
      'SubstringFilter(initial=$_initial, _any, ${_final != null ? 'final $_final' : ""})';

  @override
  bool operator ==(other) =>
      other is SubstringFilter &&
      other._filterType == _filterType &&
      other._attributeName == _attributeName &&
      other._initial == _initial &&
      other._final == _final &&
      _eq(other._any, _any);
}
