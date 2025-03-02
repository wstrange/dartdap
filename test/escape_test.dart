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
import 'dart:math';

import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import '../example/pool.dart';
import 'setup.dart';

void main() async {
  late LdapConnection ldap;

  // \2C is a comma
  final fredCN = r'fred, _smith';
  final fredRDN = RDN('cn', fredCN);
  final userDN = DN('ou=users,dc=example,dc=com');

  final fredDN = DN.fromRDNs([fredRDN, ...userDN.rdns]);
  final roleDN = DN('cn=adminRole,dc=example,dc=com');

  final testCN = 'téstè  (testy)';
  final testRDN = RDN('cn', testCN);
  final testDN = DN.fromRDNs([testRDN, ...userDN.rdns]);

  setUpAll(() async {
    ldap = defaultConnection(ssl: true);
    await ldap.open();
    await ldap.bind();
  });

  setUp(() async {
    await deleteIfExists(ldap, roleDN);
    await deleteIfExists(ldap, fredDN);
    await deleteIfExists(ldap, testDN);

    // Create test users
    try {
      await setupBaseEntries(ldap);

      print('creating $fredDN  from RDN $fredRDN');

      var r = await ldap.add(fredDN, {
        'objectClass': ['inetOrgPerson'],
        'cn': fredCN,
        'sn': 'fred',
        'userPassword': 'password',
      });

      print(r.diagnosticMessage);

      print('creating $testDN');

      r = await ldap.add(testDN, {
        'objectClass': ['inetOrgPerson'],
        'cn': testCN,
        'sn': 'testy tester',
        'userPassword': 'password',
      });

      print(r.diagnosticMessage);
    } catch (e, stack) {
      // ignore
      print('Ignored add person Exception: $e, stackTrace: $stack');
    }

    try {
      // Create the test role with the above test users
      await ldap.add(roleDN, {
        'cn': 'adminRole',
        'objectClass': ['organizationalRole'],
        'roleOccupant': [
          fredDN.toString(),
          testDN.toString(),
        ],
      });
    } catch (e) {
      // ignore
      print('Ignored add role Exception: $e');
    }

    await debugSearch(ldap);
  });

  tearDown(() async {
    // clean up
    await deleteIfExists(ldap, roleDN);
    await deleteIfExists(ldap, fredDN);
    await deleteIfExists(ldap, testDN);
  });

  // just here for debugging. Normally skipped
  test('server query', () async {
    var r = await ldap.query(DN('dc=example,dc=com'), '(objectclass=*)', ['cn', 'dn', 'objectClass', 'roleOccupant']);
    await for (final e in r.stream) {
      print('query: $e');
      // e.attributes.forEach((k, v) => print('  $k: $v'));
    }

    // get the
  }, skip: false);

  test('Find the test user we just created', () async {
    // now serach by DN
    var x = await ldap.query(testDN, '(objectClass=*)', ['cn', 'dn'], scope: SearchScope.BASE_LEVEL);

    var result = await x.getLdapResult();
    expect(result.resultCode, equals(ResultCode.OK));
    await printResults(x);
  });

  test('search for role with escaped comma using equals', () async {
    final filter = Filter.equals("roleOccupant", fredDN.toString());

    var r = await ldap.search(roleDN, filter, ['cn', 'roleOccupant']);
    var foundIt = false;
    await for (final e in r.stream) {
      print('role matching: $e');
      expect(e.dn, equals(roleDN));
      foundIt = true;
      var roleOccupant = e.attributes['roleOccupant'];
      // iterate through the roleOccupant DNs and make sure we can find the users
      for (var d in roleOccupant!.values) {
        var dn = DN.preEscaped(d);
        print('looking up $dn');
        var x = await ldap.query(dn, '(objectClass=*)', ['cn', 'dn', 'sn'], scope: SearchScope.BASE_LEVEL);
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
    final filter = '(roleOccupant=$fredDN)';

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

  test('query role for user with an escaped filter query', () async {
    // Because testDN contains parens, we need to escape them
    // for use in the filter.
    final esc = escapeNonAscii(testDN.toString(), escapeParentheses: true);
    final filter = '(roleOccupant=$esc)';

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

  test('query role for user using constructed Filter', () async {
    // Because testDN contains parens, we need to escape them
    // for use in the filter.
    final filter = Filter.equals('roleOccupant', testDN.toString());

    var r = await ldap.search(roleDN, filter, ['cn', 'roleOccupant']);
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

  test('Bind with escaped DN', () async {
    print('binding with $testDN. Escaped dn: $testDN');

    // make a new ldap connection for testing the bind
    var l = LdapConnection(
        host: 'localhost',
        port: 1636,
        ssl: true,
        // We ignore any certificate errors for testing purposes..
        badCertificateHandler: (cert) => true);

    await l.open();

    var r = await l.bind(dn: testDN, password: 'password');
    expect(r.resultCode, equals(ResultCode.OK));

    print('binding with $fredDN. Escaped dn: $fredDN');
    // now try with Fred
    r = await l.bind(dn: fredDN, password: 'password');
    expect(r.resultCode, equals(ResultCode.OK));

    await l.close();
  });
}
