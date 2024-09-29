import 'package:asn1lib/asn1lib.dart';
import 'package:dartdap/dartdap.dart';
import 'package:petitparser/petitparser.dart';

// Create LDAP Queries using https://tools.ietf.org/html/rfc2254 syntax

final _queryDefinition = QueryParserDefinition();
final _parser = _queryDefinition.build();

Filter parseQuery(String input) {
  var result = _parser.parse(input);
  if (result is Success) {
    return result.value;
  } else {
    throw LdapParseException(
        'Cant parse filter \'$input\'. Error is ${result.message}');
  }
}

// Regex for a backslash followed by two hex digits
final _regex = RegExp(r'\\([0-9a-fA-F]{2})');

// The grammar turns the parsed stream into a Filter
class QueryParserDefinition extends QueryGrammarDefinition {
  const QueryParserDefinition();

  @override
  Parser attr() => super.attr().flatten();
  @override
  Parser value() => super.value().flatten();

  @override
  Parser filter() => super.filter().map((each) => each[1]);

  @override
  Parser<List<Filter>> filterlist() => super.filterlist().map((each) {
        return List<Filter>.from(each);
        //
      });

  @override
  Parser<Filter> simple() => super.simple().map((each) {
        var token = each[1] as Token;
        var operator = token.value as String;
        var attrName = each[0];
        var val = each[2];

        val = _toASN1OctetString(val);

        switch (operator) {
          case '=':
            return Filter.equals(attrName, val);
          case '~=':
            return Filter.approx(attrName, val);
          case '>=':
            return Filter.greaterOrEquals(attrName, val);
          case '<=':
            return Filter.lessOrEquals(attrName, val);
          default:
            throw Exception('Parser error (bad grammar spec). Report this bug');
        }
      });

  @override
  Parser<Filter> and() =>
      super.and().map((each) => Filter.and(List<Filter>.from(each[1])));

  @override
  Parser<Filter> or() =>
      super.or().map((each) => Filter.or(List<Filter>.from(each[1])));

  @override
  Parser<Filter> not() => super.not().map((each) => Filter.not(each[1]));

  // flatten the nested list - omitting the * token. See the substring() method
  List<String> _flatten(List each) {
    var s = <String>[];
    for (var val in each) {
      if (val is List) {
        s.addAll(_flatten(val));
      } else if (val is String) {
        s.add(val);
      }
    }
    return s;
  }

  // Complex - but see the grammar rule in the super class for an explanation
  @override
  Parser<Filter> substring() => super.substring().map((each) {
        var init = each[2];
        var finalVal = each[4];
        var any = _flatten(each[3]);

        // There is a special case where the substring grammar also
        // matches the present filter. This can possibly
        // be fixed in the grammar spec - but this works:
        if (init == null && finalVal == null && any.isEmpty) {
          return Filter.present(each[0]);
        }

        return SubstringFilter.rfc224(each[0], // attribute name
            initial: init,
            any: any,
            finalValue: finalVal);
      });

  // Returns an ASN1OctetString.
  ASN1OctetString _toASN1OctetString(String val) =>
      ASN1OctetString(_decodeEscapedHex(val));

  String _decodeEscapedHex(String input) {
    return input.replaceAllMapped(_regex, (match) {
      return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
    });
  }
}

// Typedef to keep pedantic happy
typedef _ParserFunc = Parser<dynamic> Function();

// Grammar comments taken from: https://tools.ietf.org/html/rfc2254
class QueryGrammarDefinition extends GrammarDefinition {
  const QueryGrammarDefinition();

  Parser token(Object input) {
    if (input is Parser) {
      return input.token().trim();
    } else if (input is String) {
      return token(input.length == 1 ? char(input) : string(input));
    } else if (input is _ParserFunc) {
      return token(ref0(input));
    }
    throw ArgumentError.value(input, 'invalid token parser');
  }

  Parser LPAREN() => ref1(token, '(');

  Parser RPAREN() => ref1(token, ')');

  Parser and() => ref1(token, '&') & ref0(filterlist);

  Parser or() => ref1(token, '|') & ref0(filterlist);

  Parser not() => ref1(token, '!') & ref0(filter);

  Parser EQUAL() => ref1(token, '=');

  Parser approx() => ref1(token, '~=');

  Parser GREATER() => ref1(token, '>=');

  Parser LESS() => ref1(token, '<=');

  // NOTE: This needs to be uppercase to avoid conflict with the petit star()
  Parser STAR() => ref1(token, '*');

  //  filterlist = 1*filter
  Parser filterlist() => ref0(filter).plus();

  @override
  Parser start() => ref0(filter).end();

  //  filter     = '(' filtercomp ')'
  Parser filter() => LPAREN() & ref0(filtercomp) & RPAREN();

  //  filtercomp = and / or / not / item
  Parser filtercomp() => ref0(and) | ref0(or) | ref0(not) | ref0(item);

  // item       = simple / present / substring / extensible
  Parser item() => ref0(substring) | ref0(simple) | ref0(present);
  //       ref0(substring).starGreedy(STAR()) | ref0(simple) | ref0(present);
  //Parser item() => ref0(simple) | ref0(present) | ref0(substring) | ref0(extensible);

  //  simple     = attr filtertype value
  Parser simple() => ref0(attr) & ref0(filtertype) & ref0(value);

  //  filtertype = equal / approx / greater / less
  Parser filtertype() =>
      ref0(EQUAL) | ref0(approx) | ref0(GREATER) | ref0(LESS);

  //  present    = attr '=*'
  Parser present() => ref0(attr) & ref1(token, '=*');

  // todo: implement extensible matching rule
  //  extensible = attr [':dn'] [':' matchingrule] ':=' value
  //  / [':dn'] ':' matchingrule ':=' value

  //  subtstring match
  //  substring  = attr '=' [initial] any [final]
  //  [notation] means 'optional'
  Parser substring() =>
      ref0(attr) &
      ref0(EQUAL) &
      ref0(initial).optional() &
      ref0(_any) &
      ref0(_final).optional();

  //  initial    = value
  Parser initial() => ref0(value);
  // final = value  - we use _final because final is a reserved word
  Parser _final() => ref0(value);

  //  any        = '*' *(value '*')
  Parser _any() => STAR() & (ref0(value) & STAR()).star();

  //  attr       = AttributeDescription from Section 4.1.5 of [1]
  Parser attr() => pattern('a-zA-Z0-9.').plus();

  // todo:
  //  matchingrule = MatchingRuleId from Section 4.1.9 of [1]

  //  value      = AttributeValue from Section 4.1.6 of [1]
  // todo: This needs to allow the escape sequence, unicode characters, etc
  // See https://tools.ietf.org/html/rfc4512
  // Note: The petit pattern uses ^ to invert the match.
  // Works - but is not complete / correct.
  Parser value() => pattern(r'a-zA-Z0-9 \,=_.', 'attribute value').plus();
}
