import 'package:dartdap/dartdap.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/petitparser.dart' as prefix0;
import 'filter.dart';

// Create LDAP Queries using https://tools.ietf.org/html/rfc2254 syntax

final queryParser = QueryParser();

class QueryParser<Filter> extends GrammarParser {
  QueryParser() : super(QueryParserDefinition());

  // Parse the rfc2254 search filter and and return a [Filter]
  // throws [LdapParseException] if the input can not be parsed.
  // TODO: Consider caching queries
  Filter getFilter(String input) {
    var result = this.parse(input);

    if (result.isSuccess)
      return result.value;
    else
      throw new LdapParseException(
          "Can't parse filter '$input'. Error is ${result.message}");
  }
}

// The grammar turns the parsed stream into a Filter
class QueryParserDefinition extends QueryGrammarDefinition {
  const QueryParserDefinition();

  Parser attr() => super.attr().flatten();
  Parser value() => super.value().flatten();

  Parser filter() => super.filter().map((each) => each[1]);

  Parser<List<Filter>> filterlist() => super.filterlist().map((each) {
        return List<Filter>.from(each);
        //
      });

  Parser<Filter> simple() => super.simple().map((each) {
        var token = each[1] as Token;
        var s = token.value as String;
        var attrName = each[0];
        var val = each[2];
        // todo: There is prolly a better way to do this..
        switch (s) {
          case '=':
            return Filter.equals(attrName, val);
          case '~=':
            return Filter.approx(attrName, val);
          case '>=':
            return Filter.greaterOrEquals(attrName, val);
          case '<=':
            return Filter.lessOrEquals(attrName, val);
          default:
            throw Exception("Parser error (bad grammar spec). Report this bug");
        }
      });

  Parser<Filter> and() =>
      super.and().map((each) => Filter.and(List<Filter>.from(each[1])));

  Parser<Filter> or() =>
      super.or().map((each) => Filter.or(List<Filter>.from(each[1])));

  Parser<Filter> not() => super.not().map((each) => Filter.not(each[1]));

  // This doesn't appear to work. The substring grammar matches before this.
  Parser<Filter> present() =>
      super.present().map((each) => Filter.present(each[0]));

  // todo: There must be a better way to get petit parser to flatten this
  List<String> _flatten(List each) {
    var s = List<String>();
    each.forEach((val) {
      if (val is List)
        s.addAll(_flatten(val));
      else if (val is String) s.add(val);
    });
    return s;
  }

  // Complex - but see the grammar rule in the super class for an explanation
  Parser<Filter> substring() => super.substring().map((each) {
        var init = each[2];
        var finalVal = each[4];
        var any = _flatten(each[3]);

        // There is a special case where the substring grammar also
        // matches the present filter. This can possibly
        // be fixed in the grammar spec - but this works:
        if (init == null && finalVal == null && any.length == 0) {
          return Filter.present(each[0]);
        }

        return SubstringFilter.rfc224(each[0], // attribute name
            initial: init,
            any: any,
            finalValue: finalVal);
      });
}

class QueryGrammar extends GrammarParser {
  QueryGrammar() : super(QueryGrammarDefinition());
}

// Grammar comments taken from: https://tools.ietf.org/html/rfc2254
class QueryGrammarDefinition extends GrammarDefinition {
  const QueryGrammarDefinition();

  Parser token(Object input) {
    if (input is Parser) {
      return input.token().trim();
    } else if (input is String) {
      return token(input.length == 1 ? char(input) : string(input));
    } else if (input is Function) {
      return token(ref(input));
    }
    throw ArgumentError.value(input, 'invalid token parser');
  }

  Parser LPAREN() => ref(token, '(');

  Parser RPAREN() => ref(token, ')');

  Parser and() => ref(token, '&') & ref(filterlist);

  Parser or() => ref(token, '|') & ref(filterlist);

  Parser not() => ref(token, '!') & ref(filter);

  Parser EQUAL() => ref(token, '=');

  Parser approx() => ref(token, '~=');

  Parser GREATER() => ref(token, '>=');

  Parser LESS() => ref(token, '<=');

  // NOTE: This needs to be uppercase to avoid conflict with the petit star()
  Parser STAR() => ref(token, '*');

  //  filterlist = 1*filter
  Parser filterlist() => ref(filter).plus();

  @override
  Parser start() => ref(filter).end();

  //  filter     = "(" filtercomp ")"
  Parser filter() => LPAREN() & ref(filtercomp) & RPAREN();

  //  filtercomp = and / or / not / item
  Parser filtercomp() => ref(and) | ref(or) | ref(not) | ref(item);

  // item       = simple / present / substring / extensible
  // todo: Implement extensible
  Parser item() => ref(substring) | ref(simple) | ref(present);
  //       ref(substring).starGreedy(STAR()) | ref(simple) | ref(present);
  //Parser item() => ref(simple) | ref(present) | ref(substring) | ref(extensible);

  //  simple     = attr filtertype value
  Parser simple() => ref(attr) & ref(filtertype) & ref(value);

  //  filtertype = equal / approx / greater / less
  Parser filtertype() => ref(EQUAL) | ref(approx) | ref(GREATER) | ref(LESS);

  //  present    = attr "=*"
  // always matches the substring!!!!
  Parser present() => ref(attr) & ref(token, '=*');

  // todo:
  //  extensible = attr [":dn"] [":" matchingrule] ":=" value
  //  / [":dn"] ":" matchingrule ":=" value

  //  substring  = attr "=" [initial] any [final]
  //  [notation] means "optional"
  Parser substring() =>
      ref(attr) &
      ref(EQUAL) &
      ref(initial).optional() &
      ref(any) &
      ref(_final).optional();

  //  initial    = value
  Parser initial() => ref(value);
  // final = value  - we use _final because final is a reserved word
  Parser _final() => ref(value);

  //  any        = "*" *(value "*")
  Parser any() => STAR() & (ref(value) & STAR()).star();
  //Parser any() => STAR() & (value() & STAR());
  // Parser any() => STAR() & starValue();

  //Parser starValue() => (ref(value) & STAR() & starValue()).optional();

//  final      = value

  //  attr       = AttributeDescription from Section 4.1.5 of [1]
  Parser attr() => word().plus();

  // todo:
  //  matchingrule = MatchingRuleId from Section 4.1.9 of [1]

  //  value      = AttributeValue from Section 4.1.6 of [1]
  // todo: This needs to allow the escape sequence.  \xx
  // Parser value() => letter() & word().star();
  Parser value() => word().plus();
}
