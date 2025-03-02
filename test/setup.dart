/// Test Setup Utilities
///

import 'package:dartdap/dartdap.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

/// Set up Logging
setupLogging() {
  hierarchicalLoggingEnabled = true;

  // Root level - all levels below inherit this.
  Logger.root.level = Level.INFO; //
  // Logger.root.level = Level.FINEST; //

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
      bindDN: DN('cn=admin,dc=example,dc=com'),
      port: ssl ? 1636 : 1389,
      ssl: ssl,
      // We ignore any certificate errors for testing purposes..
      badCertificateHandler: (cert) => true);
}

final baseDN = DN('dc=example,dc=com');
final peopleDN = DN('ou=users,$baseDN');
final groupsDN = DN('ou=groups,$baseDN');

Future<void> debugSearch(LdapConnection ldap) async {
  // Search for people
  var result = await ldap.query(baseDN, '(objectclass=*)', ['dn', 'cn']);

  await for (var entry in result.stream) {
    print('entry: $entry');
  }
}

Future<void> setupBaseEntries(LdapConnection ldap) async {
  try {
    // Add base entries
    await addIgnoreIfExists(ldap, baseDN, {
      'objectClass': ['top', 'domain'],
      'dc': 'example',
    });

    await addIgnoreIfExists(ldap, peopleDN, {
      'objectClass': ['top', 'organizationalUnit'],
      'ou': 'users',
    });

    await addIgnoreIfExists(ldap, groupsDN, {
      'objectClass': ['top', 'organizationalUnit'],
      'ou': 'groups',
    });
  } catch (e) {
    print('Ignored Error setting up base entries: $e');
  }
}

// Try to delete an entry, but ignore any exceptions
// Used in tests for clean up.
Future<void> deleteIfExists(LdapConnection ldap, DN dn) async {
  try {
    await ldap.delete(dn);
  } catch (e) {
    // ignore any exceptions
  }
}

Future<void> addIgnoreIfExists(LdapConnection ldap, DN dn, Map<String, dynamic> attributes) async {
  try {
    await ldap.add(dn, attributes);
  } catch (e) {
    // ignore any exceptions
  }
}

// Utility to check attribute for non null and expected value
void expectSingleAttributeValue(SearchEntry entry, String attributeName, String expectedValue) {
  var attrs = entry.attributes[attributeName];
  if (attrs == null) {
    fail('Attribute $attributeName not found');
  }
  expect(attrs.values.length, equals(1));
  expect(attrs.values.first, equals(expectedValue));
}

// Utility to check attribute for non null and expected value startsWith
void expectSingleAttributeValueStartsWith(SearchEntry entry, String attributeName, String startsWith) {
  var attrs = entry.attributes[attributeName];
  if (attrs == null) {
    fail('Attribute $attributeName not found');
  }
  expect(attrs.values.length, equals(1));
  var s = attrs.values.first as String;
  expect(s.startsWith(startsWith), isTrue);
}

// Utility to print search results
Future<void> printSearchResults(SearchResult searchResult) async {
  var result = await searchResult.getLdapResult();
  print('got result = $result');
  if (result.resultCode == ResultCode.OK || result.resultCode == ResultCode.SIZE_LIMIT_EXCEEDED) {
    print('ok');
    await searchResult.stream.forEach((entry) {
      print('entry: $entry');
    });
  } else {
    print('ldap error ${result.resultCode}');
  }
}
