/// Test Setup Utilities
///

import 'package:dartdap/dartdap.dart';
import 'package:logging/logging.dart';

/// Set up Logging
setupLogging() {
  hierarchicalLoggingEnabled = true;

  // Root level - all levels below inherit this.
  Logger.root.level = Level.INFO; //

  // Examples of selective logging
  // Logger('ldap.send').level = Level.FINE;
  // Logger("ldap.send.ldap").level = Level.FINE;
  // Logger("ldap.recv.ldap").level = Level.FINE;
  // Logger("ldap.recv.ldap").level = Level.ALL;
  // Logger("ldap.recv.asn1").level = Level.FINER;
  // Logger("ldap.recv.bytes").level = Level.FINE;

  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

/// Default Connection used for tests
/// Edit this to match your LDAP server settings
/// This also calls setupLogging()
LdapConnection defaultConnection({bool ssl = false}) {
  setupLogging();

  return LdapConnection(
      host: 'localhost',
      password: 'password',
      bindDN: 'cn=admin,dc=example,dc=com',
      port: ssl ? 1636 : 1389,
      ssl: ssl,
      // We ignore any certificate errors for testing purposes..
      badCertificateHandler: (cert) => true);
}

const baseDN = 'dc=example,dc=com';
final peopleDN = DN('ou=users,$baseDN');
final groupsDN = DN('ou=groups,$baseDN');

Future<void> debugSearch(LdapConnection ldap) async {
  // Search for people
  var result = await ldap.query(baseDN, '(objectclass=*)', ['dn']);

  await for (var entry in result.stream) {
    print('entry: $entry');
  }
}

Future<void> deleteIfNotExist(LdapConnection ldap, String dn) async {
  try {
    await ldap.delete(dn);
  } catch (e) {
    // ignore any exceptions
  }
}
