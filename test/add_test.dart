// Tests adding entries to the LDAP directory.
//
// Depends on delete and search working.
//
//----------------------------------------------------------------

import 'dart:async';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import 'setup.dart';
// Test branch

// const branchOU = 'entry_add_test,$baseDN';
// const branchDescription = 'Branch for $branchOU';
// final branchDN = DN('ou=$branchOU,$baseDN');

final branchAttrs = {
  'objectclass': ['organizationalUnit'],
  // xs'description': branchDescription
};

// Test person

final testPersonSurname = 'Citizen';
final testPersonAttrs = {
  'objectclass': ['person'],
  'sn': testPersonSurname,
  'description': 'Test person'
};

final testPersonCN = 'John Citizen';
final testPersonDN = DN('cn=$testPersonCN,${peopleDN.dn}');

//----------------------------------------------------------------

/// Purge entries from the test to clean up

Future purgeEntries(LdapConnection ldap, DN testPersonDN, DN branchDN) async {
  // Purge test person

  try {
    await ldap.delete(testPersonDN.dn);
  } catch (e) {
    // ignore any exceptions
  }

  // Purge branch

  // try {
  //   await ldap.delete(branchDN.dn);
  // } catch (e) {
  //   // ignore any exceptions
  // }
}

//----------------------------------------------------------------

void main() {
  late LdapConnection ldap;

  setUpAll(() async {
    ldap = defaultConnection(ssl: true);
  });

  setUp(() async {
    await ldap.open();
    await ldap.bind();
    await purgeEntries(ldap, testPersonDN, peopleDN);
    await debugSearch(ldap);
    // Nothing to populate, since these tests exercise the 'add' operation
  });

  tearDown(() async {
    await purgeEntries(ldap, testPersonDN, peopleDN);
    await ldap.close();
  });

  test('adding a person entry', () async {
    var result = await ldap.add(testPersonDN.dn, testPersonAttrs);
    expect(result.resultCode, equals(0));
  });

  test('adding an entry under non-existant OU fails', () async {
    // Attempt to add the test person (without first adding the branch entry)

    try {
      final dn = 'cn=nonExistant, ou=junk, ${peopleDN.dn}';
      await ldap.add(dn, testPersonAttrs);
      fail('exception not thrown');
    } catch (e) {
      expect(e, const TypeMatcher<LdapResultNoSuchObjectException>());
    }
  });

  //----------------

  test('adding an entry with missing mandatory attribute fails', () async {
    // Attempt to add the test person missing a mandatory attribute

    final attrsMissingMandatory = {
      'objectclass': ['person'],
      'description': 'Test person'
      // no 'sn' attribute, which is mandatory in the 'person' schema
    };

    try {
      await ldap.add(testPersonDN.dn, attrsMissingMandatory);
      fail('exception not thrown');
    } catch (e) {
      expect(e, const TypeMatcher<LdapResultObjectClassViolationException>());
    }
  });
}
