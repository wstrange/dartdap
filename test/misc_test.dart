import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';

void main() {
  /*
  test('Escape ldap search string test', () {
    expect(_LdapUtil.escapeString('F*F'), equals('F\\2aF'));
    expect(_LdapUtil.escapeString('\\'), equals('\\5c'));
    expect(_LdapUtil.escapeString('(cn=foo*)'), equals('\\28cn=foo\\2a\\29'));
  });
  */

  test('LDAP Filter composition ', () {
    //var xx = Filter.substring('cn=foo');

    var f1 = SubstringFilter.fromPattern('cn', 'foo*');
    expect(f1.any, isEmpty);
    expect(f1.initial, equals('foo'));
    expect(f1.finalString, isNull);

    var f2 = SubstringFilter.fromPattern('cn', '*bar');
    expect(f2.initial, isNull);
    expect(f2.any, isEmpty);
    expect(f2.finalString, equals('bar'));

    //var c1 =  f1 & f2;

    //print(c1.toString());

    var f3 = Filter.or(
        [Filter.equals('givenName', 'A'), Filter.equals('sn', 'Annas')]);
    //print('f3 = $f3 asn1=${f3.toASN1()}');
    // make sure this encodes without throwing exception.
    f3.toASN1().encodedBytes;
  });

  test('Attribute equality', () {
    var a1 = Attribute('cn', 'Foo');
    var a2 = Attribute('cn', 'Foo');

    expect(a1, equals(a2));
  });

  test('Convert Map to attribute Map', () {
    // map has a mix of string, list and Attribute types
    var m = {
      'cn': 'Foo',
      'sn': ['one', 'two'],
      'objectclass': Attribute('objectclass', ['top', 'inetorgperson'])
    };

    var m2 = Attribute.newAttributeMap(m);

    m2.forEach((k, v) => expect(v, const TypeMatcher<Attribute>()));

    expect(m2, containsPair('cn', Attribute('cn', 'Foo')));
    expect(m2, containsPair('sn', Attribute('sn', ['two', 'one'])));
    expect(
        m2,
        containsPair(
            'objectclass', Attribute('objectclass', ['top', 'inetorgperson'])));
  });
/*
  test('Modifications',  () {
    var m = Modification.modList([
      ['a','sn','Mickey Mouse']
                                  ]);
    //print('$m');

  });
*/
}
