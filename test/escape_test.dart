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

import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';

import 'util.dart' as util;

void main() {
  final config = util.Config();
  late LdapConnection ldap;

  final fredDNEscaped = r'cn=fred\2C smith,ou=users,dc=example,dc=com';
  final fredDN = r'cn=fred\, smith,ou=users,dc=example,dc=com';
  final roleDN = 'cn=adminRole,dc=example,dc=com';

  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec.message}');
  });

  Logger.root.level = Level.INFO;

  setUpAll(() async {
    var l = config.directory(util.noLdapsDirectoryName);
    ldap = l.getConnection();

    await ldap.open();
    await ldap.bind(
        DN: config.defaultDirectory.bindDN,
        password: config.defaultDirectory.password);

    try {
      await ldap.delete(roleDN);
      await ldap.delete(fredDN);
    } catch (e) {
      // ignore
    }

    // Create the test user with a comma in the RDN
    await ldap.add(fredDN, {
      'objectClass': ['inetOrgPerson'],
      'cn': r'fred\, smith',
      'sn': 'fred',
    });

    // Create the test role with the above test user
    await ldap.add(roleDN, {
      'cn': 'adminRole',
      'objectClass': ['top', 'organizationalRole'],
      'roleOccupant': [
        'cn=test,ou=users,dc=example,dc=com',
        fredDNEscaped,
      ],
    });
  });

  tearDownAll(() async {
    // clean up
    await ldap.delete(roleDN);
    await ldap.delete(fredDN);
    await ldap.close();
  });

  // just here for debugging. Normally skipped
  test('server query', () async {
    var r = await ldap.query(
        'dc=example,dc=com', '(objectclass=*)', ['cn', 'dn', 'objectClass']);
    await for (final e in r.stream) {
      print(e);
    }
  }, skip: true);

  test('search for role with escaped comma using equals', () async {
    final filter = Filter.equals("roleOccupant", fredDNEscaped);
    var r = await ldap.search(roleDN, filter, []);
    var foundIt = false;
    await for (final e in r.stream) {
      print(e);
      expect(e.dn, equals(roleDN));
      foundIt = true;
    }
    expect(foundIt, true);
  });

  test('get role with an escaped query', () async {
    // the backslash is escaped in the filter
    final filter =
        r'(roleOccupant=cn=fred\5c, smith,ou=users,dc=example,dc=com)';

    var r = await ldap.query(roleDN, filter, ['cn', 'roleOccupant']);
    var foundIt = false;
    await for (final e in r.stream) {
      expect(e.dn, equals(roleDN));
      foundIt = true;
      print(e);
    }
    expect(foundIt, true);
  });

  test('add user with a comma', () async {
    final dn = r'cn=fred\, smith,ou=users,dc=example,dc=com';
    await ldap.delete(dn);

    var r = await ldap.add(dn, {
      'objectClass': ['inetOrgPerson'],
      'cn': r'fred\, smith',
      'sn': 'fred',
    });

    expect(r.resultCode, equals(ResultCode.OK));
  });
}
