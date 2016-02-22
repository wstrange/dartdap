// Tests deleting entries from the LDAP directory.
//
// Depends on add and search working.
//
//----------------------------------------------------------------

import 'dart:async';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';

//----------------------------------------------------------------

const String testConfigFile = "test/TEST-config.yaml";

// Base

final baseDN = new DN("dc=example,dc=com");

// Test branch

const branchOU = "entry_delete_test";
const branchDescription = "Branch for $branchOU";

final branchDN = baseDN.concat("ou=$branchOU");
final branchAttrs = {
  "objectclass": ["organizationalUnit"],
  "description": branchDescription
};

// Test person

const testPersonCN = "John Citizen"; // mandatory attribute (in person schema)
const testPersonSurname = "Citizen"; // mandatory attribute
const testPersonDescription = "Test person"; // optional attribute

var testPersonDN = branchDN.concat("cn=$testPersonCN");
final testPersonAttrs = {
  "objectclass": ["person"],
  "sn": testPersonSurname,
  "description": testPersonDescription
};

//----------------------------------------------------------------
// Create entries needed for testing.

Future populateEntries(LDAPConnection ldap) async {
  var addResult = await ldap.add(branchDN.dn, branchAttrs);
  assert(addResult is LDAPResult);
  assert(addResult.resultCode == 0);

  addResult = await ldap.add(testPersonDN.dn, testPersonAttrs);
  assert(addResult is LDAPResult);
  assert(addResult.resultCode == 0);
}

//----------------------------------------------------------------
/// Clean up before/after testing.

Future purgeEntries(LDAPConnection ldap) async {
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

void doTest(String configName) {
  var ldapConfig;
  var ldap;

  //----------------

  setUp(() async {
    ldapConfig = new LDAPConfiguration.fromFile(testConfigFile, configName);
    ldap = await ldapConfig.getConnection();
    await purgeEntries(ldap);
    await populateEntries(ldap);
  });

  //----------------

  tearDown(() async {
    await purgeEntries(ldap);
    await ldapConfig.close();
  });

  //----------------

  test("deleting an entry", () async {
    // Delete the entry

    var delResult = await ldap.delete(testPersonDN.dn);
    expect(delResult, new isInstanceOf<LDAPResult>());
    expect(delResult.resultCode, equals(0));

    // Search to check the entry is gone

    var filter = Filter.equals("cn", testPersonCN);
    var searchAttrs = ["ou"];

    var count = 0;

    await for (SearchEntry _
        in ldap.search(baseDN.dn, filter, searchAttrs).stream) {
      fail("Entry still exists after delete");
      count++;
    }

    expect(count, equals(0));
  });

  //----------------

  test("deleting a non-existant entry raises an exception", () async {
    var nosuchDN = branchDN.concat("cn=NoSuchPerson");

    expect(ldap.delete(nosuchDN.dn), throwsA(new isInstanceOf<LDAPResult>()));
  });

  //----------------

  test("deleting an entry with children raises an exception", () async {
    // Note: the test person entry is a child of the branch entry, so
    // the branch entry cannot be deleted.

    expect(ldap.delete(branchDN.dn), throwsA(new isInstanceOf<LDAPResult>()));
  });
}

//================================================================

main() {
  group("LDAP", () => doTest("test-LDAP"));

  // group("LDAPS", () => doTest("test-LDAPS")); // uncomment to test with LDAPS
}
