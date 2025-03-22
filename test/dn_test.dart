import 'package:dartdap/dartdap.dart';
import 'package:test/test.dart';

void main() {
  group('DN', () {
    test('concat', () {
      final dn1 = DN('dc=example,dc=com');
      final dn2 = dn1.concat('ou=people');
      expect(dn2.toString(), 'ou=people,dc=example,dc=com');
    });

    test('equality', () {
      final dn1 = DN('dc=example,dc=com');
      final dn2 = DN('dc=example,dc=com');
      final dn3 = DN('ou=people,dc=example,dc=com');
      expect(dn1, equals(dn2));
      expect(dn1, isNot(equals(dn3)));
    });

    test('isEmpty', () {
      final dn1 = DN('');
      final dn2 = DN('dc=example,dc=com');
      expect(dn1.isEmpty, isTrue);
      expect(dn2.isEmpty, isFalse);
    });

    test('toString', () {
      final dn = DN('dc=example,dc=com');
      expect(dn.toString(), 'dc=example,dc=com');
    });

    test('escapeNonAscii', () {
      //final dn = DN('cn=测试,dc=example,dc=com');
      // expect(dn.toString(), r'cn=\e6\b5\8b\e8\af\95,dc=example,dc=com');
    });

    test('escape parentheses', () {
      final dn = DN('cn=(test),dc=example,dc=com');
      expect(dn.toString(), r'cn=(test),dc=example,dc=com');
    });
  });

  group('RDN', () {
    test('RDN escaping val', () {
      final testCN = 'téstè  (testy)';

      expect(escapeRDNValue(testCN), testCN);
    });

    test('fromString', () {
      final rdn = RDN.fromString('cn=test');
      expect(rdn.attributeName, 'cn');
      expect(rdn.attributeValue, 'test');
    });

    test('fromString with special characters', () {
      final rdn = RDN.fromString('cn=test+value');
      expect(rdn.attributeName, 'cn');
      expect(rdn.attributeValue, r'test\+value');
    });

    test('escapeValue', () {
      final rdn = RDN.fromNameValue('cn', 'test+value');
      expect(rdn.attributeName, 'cn');
      expect(rdn.attributeValue, 'test\\+value');
    });

    test('toString', () {
      final rdn = RDN.fromNameValue('cn', 'test');
      expect(rdn.toString(), 'cn=test');
    });

    test('escape special characters', () {
      final rdn = RDN.fromNameValue('cn', r'#test+value<>;="');
      expect(rdn.attributeValue, r'\#test\+value\<\>\;\=\"');
    });

    test('escape leading space', () {
      final rdn = RDN.fromNameValue('cn', ' test');
      expect(rdn.attributeValue, r'\ test');
    });

    test('escape trailing space', () {
      final rdn = RDN.fromNameValue('cn', 'test ');
      expect(rdn.attributeValue, r'test\ ');
    });

    test('escape leading #', () {
      final rdn = RDN.fromNameValue('cn', '#test');
      expect(rdn.attributeValue, r'\#test');
    });

    test('escape non-printable ASCII characters', () {
      final rdn = RDN.fromNameValue('cn', String.fromCharCode(0));
      expect(rdn.attributeValue, r'\00');
    });

    test('escape non-printable ASCII characters 2', () {
      final rdn = RDN.fromNameValue('cn', String.fromCharCode(15));
      expect(rdn.attributeValue, r'\0f');
    });

    test('escape non-printable ASCII characters 3', () {
      final rdn = RDN.fromNameValue('cn', String.fromCharCode(31));
      expect(rdn.attributeValue, r'\1f');
    });
  });

  group('escape DN', () {
    test('empty string', () {
      expect(escape(''), '');
    });

    test('no special characters', () {
      expect(escape('test'), 'test');
    });

    test('special characters', () {
      expect(escapeRDNValue(r'+<>#;="'), r'\+\<\>\#\;\=\"');
    });

    test('leading space', () {
      expect(escapeRDNValue(' test'), r'\ test');
    });

    test('trailing space', () {
      expect(escapeRDNValue('test '), r'test\ ');
    });

    test('leading #', () {
      expect(escapeRDNValue('#test'), r'\#test');
    });

    test('non-printable ASCII characters', () {
      expect(escapeRDNValue(String.fromCharCode(0)), r'\00');
    });

    test('DN with special characters', () {
      final dn = DN("CN=Tèster1,OU=Castus,OU=Users,OU=MyBusiness,DC=castus,DC=local");
      expect(dn.rdns.length, 6);
      expect(dn.rdns[0].attributeValue, r'T\c3\a8ster1');
      expect(dn.toString(), r'CN=T\c3\a8ster1,OU=Castus,OU=Users,OU=MyBusiness,DC=castus,DC=local');
    });
  });
}
