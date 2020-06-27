// Tests deleting entries from the LDAP directory.
//
// Depends on add and search working.
//
//----------------------------------------------------------------

import 'dart:async';

import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';

import 'util.dart' as util;

//----------------------------------------------------------------

const branchOU = "entry_delete_test";
const branchDescription = "Branch for $branchOU";

final branchAttrs = {
  "objectclass": ["organizationalUnit"],
  "description": branchDescription
};

// Test person

const testPersonCN = "John Citizen"; // mandatory attribute (in person schema)
const testPersonSurname = "Citizen"; // mandatory attribute
const testPersonDescription = "Test person"; // optional attribute

final testPersonAttrs = {
  "objectclass": ["person"],
  "sn": testPersonSurname,
  "description": testPersonDescription
};

//----------------------------------------------------------------
// Create entries needed for testing.

Future populateEntries(
    LdapConnection ldap, DN branchDN, DN testPersonDN) async {
  var addResult = await ldap.add(branchDN.dn, branchAttrs);
  assert(addResult is LdapResult);
  assert(addResult.resultCode == 0);

  addResult = await ldap.add(testPersonDN.dn, testPersonAttrs);
  assert(addResult is LdapResult);
  assert(addResult.resultCode == 0);
}

//----------------------------------------------------------------
/// Clean up before/after testing.

Future purgeEntries(LdapConnection ldap, DN branchDN, DN testPersonDN) async {
  // Purge test person

  try {
    await ldap.delete(testPersonDN.dn);
  } catch (e) {
    // ignore any exceptions thrown if entry does not exist
  }

  // Purge branch

  try {
    await ldap.delete(branchDN.dn);
  } catch (e) {
    // ignore any exceptions if entry does not exist
  }
}

//----------------------------------------------------------------

void runTests(util.ConfigDirectory connection) {
  LdapConnection ldap;
  DN testPersonDN;
  DN branchDN;

  //----------------

  setUp(() async {
    branchDN = connection.testDN.concat("ou=$branchOU");
    testPersonDN = branchDN.concat("cn=$testPersonCN");

    ldap = connection.connect();

    await purgeEntries(ldap, branchDN, testPersonDN);
    await populateEntries(ldap, branchDN, testPersonDN);
  });

  //----------------

  tearDown(() async {
    await purgeEntries(ldap, branchDN, testPersonDN);
    await ldap.close();
  });

  //----------------

  test("deleting an entry", () async {
    // Delete the entry

    var delResult = await ldap.delete(testPersonDN.dn);
    expect(delResult, const TypeMatcher<LdapResult>());
    expect(delResult.resultCode, equals(0));

    // Search to check the entry is gone

    var filter = Filter.equals("cn", testPersonCN);
    var searchAttrs = ["ou"];

    var count = 0;

    var searchResults =
        await ldap.search(connection.testDN.dn, filter, searchAttrs);
    await for (SearchEntry _ in searchResults.stream) {
      fail("Entry still exists after delete");
      // dead code
      //count++;
    }

    expect(count, equals(0));
  });

  //----------------

  test("deleting a non-existant entry raises an exception", () async {
    var nosuchDN = branchDN.concat("cn=NoSuchPerson");

    try {
      await ldap.delete(nosuchDN.dn);
      fail("exception not thrown");
    } catch (e) {
      expect(e, const TypeMatcher<LdapResultNoSuchObjectException>());
    }
  });

  //----------------

  test("deleting an entry with children raises an exception", () async {
    // Note: the test person entry is a child of the branch entry, so
    // the branch entry cannot be deleted.

    try {
      await ldap.delete(branchDN.dn);
      fail("exception not thrown");
    } catch (e) {
      expect(e, const TypeMatcher<LdapResultNotAllowedOnNonleafException>());
    }
  });
}

//================================================================

void main() {
  final config = util.Config();

  group('tests', () {
    runTests(config.defaultDirectory);
  }, skip: config.skipIfMissingDefaultDirectory);

  group('tests over LDAPS', () {
    runTests(config.directory(util.ldapsDirectoryName));
  }, skip: config.skipIfMissingDirectory(util.ldapsDirectoryName));
}
