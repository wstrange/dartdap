import 'package:petitparser/petitparser.dart';
import 'package:petitparser/petitparser.dart' as prefix0;
import 'filter.dart';

// Create LDAP Queries using https://tools.ietf.org/html/rfc2254 syntax

final queryParser = QueryParser();

class QueryParser<Filter> extends GrammarParser {
  QueryParser() : super(QueryParserDefinition());
}

// The grammar turns the parsed stream into a Filter
class QueryParserDefinition extends QueryGrammarDefinition {
  const QueryParserDefinition();

  Parser attr() => super.attr().flatten();
  Parser value() => super.value().flatten();

  Parser filter() => super.filter().map((each) => each[1]);

  Parser<List<Filter>> filterlist() => super.filterlist().map((each) {
        print(each);
        return List<Filter>.from(each);
        //
      });

  Parser<Filter> simple() =>
      super.simple().map((each) => Filter.equals(each[0], each[2]));

  Parser<Filter> and() =>
      super.and().map((each) => Filter.and(List<Filter>.from(each[1])));
  
  
  String _flatten(List each) {
    var s = "";
    each.forEach( (val) )
  }

  // Complex - but see the grammar rule in the super class for an explanation
  Parser<Filter> substring() => super.substring().map((each) {
        var x = each[3] as List;
        String any = "";
        x.forEach( (val) {
          if( val is Token )
            any += val.value;
          else if( val is List) 
        });


        return SubstringFilter.rfc224(each[0], // attribute name
            initial: each[2],
            any: any,
            finalValue: each[4]);
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

  Parser OR() => ref(token, '|') & ref(filterlist);

  Parser NOT() => ref(token, '!') & ref(filter);

  Parser EQUAL() => ref(token, '=');

  Parser APPROX() => ref(token, '~=');

  Parser GREATER() => ref(token, '>=');

  Parser LESS() => ref(token, '<=');

  Parser STAR() => ref(token, '*');

  //  filterlist = 1*filter
  Parser filterlist() => ref(filter).plus();

  @override
  Parser start() => ref(filter).end();

  //  filter     = "(" filtercomp ")"
  Parser filter() => LPAREN() & ref(filtercomp) & RPAREN();

  //  filtercomp = and / or / not / item
  Parser filtercomp() => ref(and) | ref(OR) | ref(NOT) | ref(item);

  // item       = simple / present / substring / extensible
  // todo: Implement extensible
  Parser item() => ref(substring) | ref(simple) | ref(present);
  //       ref(substring).starGreedy(STAR()) | ref(simple) | ref(present);

  //Parser item() => ref(simple) | ref(present) | ref(substring) | ref(extensible);

  //  simple     = attr filtertype value
  Parser simple() => ref(attr) & ref(filtertype) & ref(value);

  //  filtertype = equal / approx / greater / less
  Parser filtertype() => ref(EQUAL) | ref(APPROX) | ref(GREATER) | ref(LESS);

  //  present    = attr "=*"
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
  Parser any() => STAR() & (value() & STAR()).star();
//  final      = value

  //  attr       = AttributeDescription from Section 4.1.5 of [1]
  Parser attr() => word().plus();

  // todo:
  //  matchingrule = MatchingRuleId from Section 4.1.9 of [1]

  //  value      = AttributeValue from Section 4.1.6 of [1]
  // todo: This needs to allow the escape sequence.  \xx
  Parser value() => letter() & word().star();
}
