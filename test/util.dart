/// Test Utilities
///
///

import 'package:dartdap/dartdap.dart';

/// Default Connection used for tests
/// Edit this to match your LDAP server settings
LdapConnection defaultConnection({bool ssl = false}) {
  return LdapConnection(
      host: 'localhost',
      password: 'password',
      bindDN: 'cn=admin,dc=example,dc=com',
      port: ssl ? 1636 : 1389,
      ssl: ssl,
      // We ignore any certificate errors for testing purposes..
      badCertificateHandler: (cert) => true);
}
