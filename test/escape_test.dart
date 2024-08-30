///
/// This is related to #60 - improperly escaping DNs and search filters
/// https://github.com/wstrange/dartdap/issues/60
///
///
/// A good reference for this is from the Ping LDAP sdk issue:
/// https://github.com/pingidentity/ldapsdk/issues/10
///
/// From that issue "The syntax for escaping filters is different from the syntax for escaping DNs. "
///
/// https://ldap.com/ldap-dns-and-rdns/
///
///

import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';

import 'util.dart' as util;

void main() {
  final config = util.Config();
  late LdapConnection ldap;

  setUp(() async {
    Logger.root.onRecord.listen((LogRecord rec) {
      print(
          '${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec.message}');
    });

    Logger.root.level = Level.INFO;

    var l = config.directory(util.noLdapsDirectoryName);
    ldap = l.getConnection();

    await ldap.open();
    await ldap.bind(
        DN: config.defaultDirectory.bindDN,
        password: config.defaultDirectory.password);

    // await purgeEntries(ldap, testPersonDN, branchDN);
  });

  tearDown(() async {
    await ldap.close();
  });

  test('server query', () async {
    var r = await ldap.query(
        'dc=example,dc=com', '(objectclass=*)', ['cn', 'dn', 'objectClass']);

    await for (final e in r.stream) {
      print(e);
    }
  });

  test('create role', () async {
    final dn = 'cn=adminRole,dc=example,dc=com';

    final fredDN = r'cn=fred\2C smith,ou=users,dc=example,dc=com';
    await ldap.delete(dn);

    await ldap.add('cn=adminRole,dc=example,dc=com', {
      'cn': 'adminRole',
      'objectClass': ['top', 'organizationalRole'],
      'roleOccupant': [
        'cn=fred,ou=users,dc=example,dc=com',
        fredDN,
      ],
    });
  });

  test('search for role with escaped comma using equals', () async {
    // final userDN = 'cn=fred,ou=users,dc=example,dc=com';
    final userDN = r'cn=fred\2c smith,ou=users,dc=example,dc=com';
    final dn = 'cn=adminRole,dc=example,dc=com';

    final filter = Filter.equals("roleOccupant", userDN);
    var r = await ldap.search(dn, filter, []);
    var foundIt = false;
    await for (final e in r.stream) {
      print(e);
      expect(e.dn, equals(dn));
      foundIt = true;
    }
    expect(foundIt, true);
  });

  test('get role with an escaped query', () async {
    // final userDN = 'cn=fred,ou=users,dc=example,dc=com';
    final filter =
        r'(roleOccupant=cn=fred\5c, smith,ou=users,dc=example,dc=com)';
    final dn = 'cn=adminRole,dc=example,dc=com';

    var r = await ldap.query(dn, filter, ['cn', 'roleOccupant']);
    await for (final e in r.stream) {
      print(e);
    }
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
