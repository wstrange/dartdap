import 'package:dartdap/dartdap.dart';
import 'package:test/test.dart';

void main() {
  group('DN', () {
    test('concat', () {
      final dn1 = DN('dc=example,dc=com');
      final dn2 = DN('ou=people') + dn1;
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
      var s = 'cn=测试,dc=example,dc=com';
      final dn = DN(s);
      expect(dn.toString(), s);
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
      expect(rdn.attributeName.toString(), 'cn');
      expect(rdn.attributeValue.toString(), 'test');
    });

    test('fromString with special characters', () {
      final rdn = RDN.fromString('cn=test+value');
      expect(rdn.attributeName.toString(), 'cn');
      expect(rdn.attributeValue.toString(), r'test\+value');
    });

    test('escapeValue', () {
      final rdn = RDN.fromNameValue('cn', 'test+value');
      expect(rdn.attributeName.toString(), 'cn');
      expect(rdn.attributeValue.toString(), 'test\\+value');
    });

    test('toString', () {
      final rdn = RDN.fromNameValue('cn', 'test');
      expect(rdn.toString(), 'cn=test');
    });

    test('escape special characters', () {
      final rdn = RDN.fromNameValue('cn', r'#test+value<>;="');
      expect(rdn.attributeValue.toString(), r'\#test\+value\<\>\;\=\"');
    });

    test('escape leading space', () {
      final rdn = RDN.fromNameValue('cn', ' test');
      expect(rdn.attributeValue.toString(), r'\ test');
    });

    test('escape trailing space', () {
      final rdn = RDN.fromNameValue('cn', 'test ');
      expect(rdn.attributeValue.toString(), r'test\ ');
    });

    test('escape leading #', () {
      final rdn = RDN.fromNameValue('cn', '#test');
      expect(rdn.attributeValue.toString(), r'\#test');
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
      expect(escapeRDNValue(r'+<>#;="'), r'\+\<\>#\;\=\"');
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
  });
}
