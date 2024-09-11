// Tests adding entries to the LDAP directory.
//
// Depends on delete and search working.
//
//----------------------------------------------------------------

import 'dart:async';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import 'config.dart' as util;

//----------------------------------------------------------------

// Base

// Test branch

const branchOU = 'entry_add_test';
const branchDescription = 'Branch for $branchOU';

final branchAttrs = {
  'objectclass': ['organizationalUnit'],
  'description': branchDescription
};

// Test person

var testPersonSurname = 'Citizen';
final testPersonAttrs = {
  'objectclass': ['person'],
  'sn': testPersonSurname,
  'description': 'Test person'
};

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

  try {
    await ldap.delete(branchDN.dn);
  } catch (e) {
    // ignore any exceptions
  }
}

//----------------------------------------------------------------

void runTests(util.ConfigDirectory configDirectory) {
  late LdapConnection ldap;
  late DN branchDN;
  late DN testPersonDN;

  //----------------

  setUp(() async {
    branchDN = configDirectory.testDN.concat('ou=$branchOU');
    testPersonDN = branchDN.concat('cn=John Citizen');

    ldap = configDirectory.getConnection();
    await ldap.open();
    await ldap.bind();
    await purgeEntries(ldap, testPersonDN, branchDN);
    // Nothing to populate, since these tests exercise the 'add' operation
  });

  //----------------

  tearDown(() async {
    await purgeEntries(ldap, testPersonDN, branchDN);
    await ldap.close();
  });

  //----------------

  test('adding an entry', () async {
    // Add the organizationalUnit entry

    var result = await ldap.add(branchDN.dn, branchAttrs);

    expect(result.resultCode, equals(0));

    // Search for the added entry

    var filter = Filter.equals('ou', branchOU);
    var searchAttrs = ['ou', 'description'];

    var count = 0;

    var searchResult =
        await ldap.search(configDirectory.testDN.dn, filter, searchAttrs);
    await for (SearchEntry entry in searchResult.stream) {
      expect(entry, isNotNull);

      var ouSet = entry.attributes['ou'];
      if (ouSet == null) {
        fail('missting attribute: ou');
      }
      expect(ouSet.values.length, equals(1));
      expect(ouSet.values.first, equals(branchOU));

      var descSet = entry.attributes['description'];
      if (descSet == null) {
        fail('missting attribute: description');
      }
      expect(descSet.values.length, equals(1));
      expect(descSet.values.first, equals(branchDescription));

      expect(entry.attributes.length, equals(2)); // no other attributes

      count++;
    }

    expect(count, equals(1));
  });

  //----------------

  test('adding an entry that already exists fails', () async {
    // Add the People organizationalUnit entry

    var result = await ldap.add(branchDN.dn, branchAttrs);
    assert(result.resultCode == 0);

    // Try to add another entry with the same DN

    var newDescription = 'New description should not get used';

    var newAttrs = {
      'objectclass': ['organizationalUnit'],
      'description': newDescription
    };

    expect(newDescription, isNot(equals(branchDescription)));

    // Attempt to add an entry with the same DN

    try {
      await ldap.add(branchDN.dn, newAttrs);
      fail('exception not thrown');
    } catch (e) {
      expect(e, const TypeMatcher<LdapResultEntryAlreadyExistsException>());
    }

    // The original entry is present and unchanged

    var filter = Filter.equals('ou', branchOU);
    var searchAttrs = ['description', 'ou']; // also tests order does not matter

    var count = 0;

    var searchResults =
        await ldap.search(configDirectory.testDN.dn, filter, searchAttrs);
    await for (SearchEntry entry in searchResults.stream) {
      expect(entry, isNotNull);

      var ouSet = entry.attributes['ou'];

      if (ouSet == null) {
        fail('missting attribute: ou');
      }
      expect(ouSet.values.length, equals(1));
      expect(ouSet.values.first, equals(branchOU));

      var descSet = entry.attributes['description'];
      if (descSet == null) {
        fail('missing attribute: description');
      }
      expect(descSet.values.length, equals(1));
      expect(descSet.values.first, equals(branchDescription)); // unchanged

      expect(entry.attributes.length, equals(2)); // no other attributes

      count++;
    }

    expect(count, equals(1));
  });

  //----------------

  test('adding a person entry', () async {
    // This test demonstrates that the subsequent tests would have worked, if
    // the parent entry existed and the mandatory attributes were all present.

    // Add the branch entry

    var result1 = await ldap.add(branchDN.dn, branchAttrs);
    assert(result1.resultCode == 0);

    // Add the test person

    var result = await ldap.add(testPersonDN.dn, testPersonAttrs);
    expect(result.resultCode, equals(0));
  });

  //----------------

  test('adding an entry under non-existant entry fails', () async {
    // Attempt to add the test person (without first adding the branch entry)

    try {
      await ldap.add(testPersonDN.dn, testPersonAttrs);
      fail('exception not thrown');
    } catch (e) {
      expect(e, const TypeMatcher<LdapResultNoSuchObjectException>());
    }
  });

  //----------------

  test('adding an entry with missing mandatory attribute fails', () async {
    // Add the branch entry

    var result1 = await ldap.add(branchDN.dn, branchAttrs);
    assert(result1.resultCode == 0);

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

//================================================================

void main() {
  final config = util.Config();

  group('tests over LDAPS', () {
    runTests(config.directory(util.ldapDirectoryName));
  }, skip: config.skipIfMissingDirectory(util.ldapDirectoryName));
}
