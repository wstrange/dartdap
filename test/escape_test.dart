///
/// Test for #60 - improperly escaping search filters
/// https://github.com/wstrange/dartdap/issues/60
///
///
/// A good read for this is from the Ping LDAP sdk issue:
/// https://github.com/pingidentity/ldapsdk/issues/10
///
/// "The syntax for escaping filters is different from the syntax for escaping DNs. "
///
/// https://ldap.com/ldap-dns-and-rdns/
///
///
///// This is tested against an OpenLDAP server
///
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import 'setup.dart';

void main() async {
  late LdapConnection ldap;

  // \2C is a comma
  final fredDNEscaped = r'cn=fred\2C _smith,ou=users,dc=example,dc=com';
  final fredDN = DN(r'cn=fred\, _smith,ou=users,dc=example,dc=com');
  final roleDN = DN('cn=adminRole,dc=example,dc=com');
  final tester = escapeNonAscii('téstè');
  final testDN = 'cn=$tester,dc=example,dc=com';
  final testDNEscaped = escapeNonAscii(testDN);

  // final fred = r'cn=fred, _smith,ou=users,dc=example,dc=com';

  setUpAll(() async {
    ldap = defaultConnection(ssl: true);
    await ldap.open();
    await ldap.bind();
  });

  setUp(() async {
    await deleteIfNotExist(ldap, roleDN);
    await deleteIfNotExist(ldap, fredDN);

    // Create test users
    try {
      await ldap.add(fredDN, {
        'objectClass': ['inetOrgPerson'],
        'cn': r'fred\, smith',
        'sn': 'fred',
      });

      await ldap.add(testDNEscaped, {
        'objectClass': ['inetOrgPerson'],
        'cn': escapeNonAscii('téstè'),
        'sn': 'testy tester',
      });
    } catch (e) {
      // ignore
      print('Ignored add person Exception: $e');
    }

    try {
      // Create the test role with the above test users
      await ldap.add(roleDN, {
        'cn': 'adminRole',
        'objectClass': ['organizationalRole'],
        'roleOccupant': [
          fredDNEscaped,
          'cn=user1,ou=users,dc=example,dc=com',
          testDNEscaped,
        ],
      });
    } catch (e) {
      // ignore
      print('Ignored add role Exception: $e');
    }

    //await debugSearch(ldap);
  });

  tearDown(() async {
    // clean up
    await deleteIfNotExist(ldap, roleDN);
    await deleteIfNotExist(ldap, fredDN);
    await deleteIfNotExist(ldap, testDNEscaped);
  });

  // just here for debugging. Normally skipped
  test('server query', () async {
    var r = await ldap.query(DN('dc=example,dc=com'), '(objectclass=*)',
        ['cn', 'dn', 'objectClass', 'roleOccupant']);
    await for (final e in r.stream) {
      print('query: $e');
      // e.attributes.forEach((k, v) => print('  $k: $v'));
    }
  }, skip: true);

  test('search for role with escaped comma using equals', () async {
    final filter = Filter.equals("roleOccupant", fredDNEscaped);

    var r = await ldap.search(roleDN, filter, ['cn', 'roleOccupant']);
    var foundIt = false;
    await for (final e in r.stream) {
      print('role matching: $e');
      expect(e, equals(roleDN));
      foundIt = true;
    }
    expect(foundIt, true);
  });

  test('get role with an escaped query', () async {
    // the backslash is escaped in the filter
    final filter = '(roleOccupant=$fredDNEscaped)';

    var r = await ldap.query(roleDN, filter, ['cn', 'roleOccupant']);
    var foundIt = false;
    var result = await r.getLdapResult();
    expect(result.resultCode, equals(ResultCode.OK));
    await for (final e in r.stream) {
      expect(e, equals(roleDN));
      foundIt = true;
      //print('Found role dn: ${e.dn}');
    }
    expect(foundIt, true);
  });

  test('add user with a comma', () async {
    final dn = DN(r'cn=fred\, _smith,ou=users,dc=example,dc=com');
    await ldap.delete(dn);

    var r = await ldap.add(dn, {
      'objectClass': ['inetOrgPerson'],
      'cn': r'fred\, smith',
      'sn': 'fred',
    });

    expect(r.resultCode, equals(ResultCode.OK));
  });

  test('get tester user with an escaped query', () async {
    // the backslash is escaped in the filter

    // either works...
    // final filter = '(roleOccupant=$testDN)';
    final filter = '(roleOccupant=$testDNEscaped)';

    var r = await ldap.query(roleDN, filter, ['cn', 'roleOccupant']);
    var foundIt = false;
    var result = await r.getLdapResult();
    expect(result.resultCode, equals(ResultCode.OK));
    await for (final e in r.stream) {
      expect(e.dn, equals(roleDN));
      foundIt = true;
      print('Found role dn: ${e.dn}');
    }
    expect(foundIt, true);
  });
}
