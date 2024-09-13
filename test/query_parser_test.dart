@Tags(['unit'])
library;

import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
// if you want to use the parser trace() method to wrap the
// import 'package:petitparser/debug.dart';

void main() {
  test('Basic Parser test', () {
    var babs = Filter.equals('cn', 'Babs');
    var foo = Filter.equals('sn', 'Foo');

    final m = <String, Filter>{
      '(cn=Babs)': babs,
      '(&(cn=Babs)(sn=Foo))': Filter.and([babs, foo]),
      '(|(cn=Babs)(sn=Foo))': Filter.or([babs, foo]),
      '(sn=Foo*)': SubstringFilter.rfc224('sn', initial: 'Foo'),
      '(sn=*Foo)': SubstringFilter.rfc224('sn', finalValue: 'Foo'),
      '(sn=*Foo*Baz*)': SubstringFilter.rfc224('sn', any: ['Foo', 'Baz']),
      '(!(sn=Foo*))': Filter.not(SubstringFilter.rfc224(
        'sn',
        initial: 'Foo',
      )),
      '(sn~=Foo)': Filter.approx('sn', 'Foo'),
      // A complex compound filter
      '(&(cn=Babs)(|(cn=Babs)(sn=Foo)))': Filter.and([
        babs,
        Filter.or([babs, foo])
      ]),
      '(cn=*)': Filter.present('cn'),
      // Test for some special chars in the attribute value
      // the encoding \2a is the escaped * character.
      // TODO: review attribute value escaping rules
      r'(cn=uid._\2a*)': SubstringFilter.rfc224('cn', initial: r'uid._\2a'),
    };

    m.forEach((query, filter) {
      //print('eval: $query');
      var f = parseQuery(query);
      expect(f, equals(filter));
    });
  });
}
