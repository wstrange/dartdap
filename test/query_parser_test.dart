@Tags(['unit'])
library;

import 'package:asn1lib/asn1lib.dart';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
// if you want to use the parser trace() method to wrap the
// import 'package:petitparser/debug.dart';

void main() {
  test('Basic Parser test', () {
    var babs1 = Filter.equals('cn', ASN1OctetString('Babs'));
    var babs = Filter.equals('cn', 'Babs');

    expect(babs1, equals(babs));

    var foo = Filter.equals('sn', ASN1OctetString('Foo'));

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
      print('result: $f');
      expect(f, equals(filter));
    });
  });

  // issue #65
  test('Special characters in filter', () {
    var dn = DN('CN=téstèr');
    var q = '(roleOccupant=$dn)';

    var f = parseQuery(q);

    expect(f, isA<Filter>());
    expect(f.filterType, equals(Filter.TYPE_EQUALITY));
    expect(f.attributeName, equals('roleOccupant'));
    // The special characters do not need to be escaped in this example
    var x = ASN1OctetString(r'CN=téstèr');
    expect(f.assertionValue, equals(x));
  });

  test('escaping characters', () {
    var s = r'téstèr';
    var expected = r't\c3\a9st\c3\a8r';
    var escaped = escapeNonAscii(s);
    expect(escaped, equals(expected));

    var t = r'(roleOccupant=cn=fred\5c, _smith,ou=users,dc=example,dc=com)';
    expect(t, equals(escapeNonAscii(t)), reason: 'escaped chars should not be escaped again');
  });
}
