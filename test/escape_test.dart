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
import '../example/pool.dart';
import 'setup.dart';

void main() async {
  late LdapConnection ldap;

  // \2C is a comma
  final fredDNEscaped = r'cn=fred\2C _smith,ou=users,dc=example,dc=com';
  final fredDN = DN(r'cn=fred\, _smith,ou=users,dc=example,dc=com');
  final roleDN = DN('cn=adminRole,dc=example,dc=com');
  final testDN = DN('cn=téstè (testy),ou=users,dc=example,dc=com');
  // final baseUserDN = DN('ou=users,dc=example,dc=com');
  final testerCN = escapeNonAscii('téstè  (testy)');

  setUpAll(() async {
    ldap = defaultConnection(ssl: true);
    await ldap.open();
    await ldap.bind();
  });

  setUp(() async {
    await deleteIfExists(ldap, roleDN);
    await deleteIfExists(ldap, fredDN);

    // Create test users
    try {
      await ldap.add(fredDN, {
        'objectClass': ['inetOrgPerson'],
        'cn': r'fred\, smith',
        'sn': 'fred',
      });

      await ldap.add(testDN, {
        'objectClass': ['inetOrgPerson'],
        'cn': testerCN,
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
          testDN.dn,
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
    await deleteIfExists(ldap, roleDN);
    await deleteIfExists(ldap, fredDN);
    await deleteIfExists(ldap, testDN);
  });

  // just here for debugging. Normally skipped
  // test('server query', () async {
  //   var r = await ldap.query(DN('dc=example,dc=com'), '(objectclass=*)',
  //       ['cn', 'dn', 'objectClass', 'roleOccupant']);
  //   await for (final e in r.stream) {
  //     print('query: $e');
  //     // e.attributes.forEach((k, v) => print('  $k: $v'));
  //   }

  //   // get the
  // }, skip: true);

  test('Find the test user we just created', () async {
    // now serach by DN
    var x = await ldap.query(testDN, '(objectClass=*)', ['cn', 'dn'],
        scope: SearchScope.BASE_LEVEL);

    var result = await x.getLdapResult();
    expect(result.resultCode, equals(ResultCode.OK));
    await printResults(x);
  });

  test('search for role with escaped comma using equals', () async {
    final filter = Filter.equals("roleOccupant", fredDNEscaped);

    var r = await ldap.search(roleDN, filter, ['cn', 'roleOccupant']);
    var foundIt = false;
    await for (final e in r.stream) {
      print('role matching: $e');
      expect(e.dn, equals(roleDN));
      foundIt = true;
      var roleOccupant = e.attributes['roleOccupant'];
      // iterate through the roleOccupant DNs and make sure we can find the users
      for (var d in roleOccupant!.values) {
        var dn = DN(d);
        print('looking up $dn');
        var x = await ldap.query(dn, '(objectClass=*)', ['cn', 'dn', 'sn'],
            scope: SearchScope.BASE_LEVEL);
        var result = await x.getLdapResult();

        expect(result.resultCode, equals(ResultCode.OK));

        await for (final e in x.stream) {
          print('found entry: $e');
          // e.attributes.forEach((k, v) => print('  $k: $v'));
        }
      }
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
      expect(e.dn, equals(roleDN));
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

  test('get test user with an escaped query', () async {
    // the backslash is escaped in the filter

    final filter = '(roleOccupant=${testDN.dn})';

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
