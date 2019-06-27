import 'package:petitparser/petitparser.dart';


// Create LDAP Queries using https://tools.ietf.org/html/rfc2254 syntax


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

  Parser AND() => ref(token, '&') & ref(filterlist);

  Parser OR() => ref(token, '|') & ref(filterlist);

  Parser NOT() => ref(token, '!') & ref(filter);

  Parser EQUAL() => ref(token, '=');

  Parser APPROX() => ref(token, '~=');

  Parser GREATER() => ref(token, '>=');

  Parser LESS() => ref(token, '<=');

  //  filterlist = 1*filter
  Parser filterlist() => ref(filter).plus();


  @override
  Parser start() => ref(filter).end();

  //  filter     = "(" filtercomp ")"
  Parser filter() => LPAREN() & ref(filtercomp) & RPAREN();

  //  filtercomp = and / or / not / item
  Parser filtercomp() => ref(AND) | ref(OR) | ref(NOT) | ref(item);

  // item       = simple / present / substring / extensible
  // todo: Implement extensible
  Parser item() => ref(simple) | ref(present) | ref(substring);

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
  // TOOD: must be able to parse   (o=univ*of*mich*)
  Parser substring() => ref(attr) & ref(EQUAL) & ref(initial) & ref(any) & ref(_final).optional();

  Parser initial() => ref(value);
  Parser _final() => ref(value);

  //  initial    = value
  //  any        = "*" *(value "*")
  Parser any() => ref(token,'*');
//  final      = value

  //  attr       = AttributeDescription from Section 4.1.5 of [1]
  Parser attr() => word().plus();

  //  matchingrule = MatchingRuleId from Section 4.1.9 of [1]

  //  value      = AttributeValue from Section 4.1.6 of [1]
  Parser value() => letter() & word().star();

}