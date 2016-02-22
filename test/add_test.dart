// Tests adding entries to the LDAP directory.
//
// Depends on delete and search working.
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

const branchOU = "entry_add_test";
const branchDescription = "Branch for $branchOU";

final branchDN = baseDN.concat("ou=$branchOU");
final branchAttrs = {
  "objectclass": ["organizationalUnit"],
  "description": branchDescription
};

// Test person

var testPersonDN = branchDN.concat("cn=John Citizen");
var testPersonSurname = "Citizen";
final testPersonAttrs = {
  "objectclass": ["person"],
  "sn": testPersonSurname,
  "description": "Test person"
};

//----------------------------------------------------------------

/// Purge entries from the test to clean up

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

void doTests(String configName) {
  var ldapConfig;
  var ldap;

  //----------------

  setUp(() async {
    ldapConfig = new LDAPConfiguration.fromFile(testConfigFile, configName);
    ldap = await ldapConfig.getConnection();
    await purgeEntries(ldap);
    // Nothing to populate, since these tests exercise the "add" operation
  });

  //----------------

  tearDown(() async {
    await purgeEntries(ldap);
    await ldapConfig.close();
  });

  //----------------

  test("adding an entry", () async {
    // Add the organizationalUnit entry

    var result = await ldap.add(branchDN.dn, branchAttrs);

    expect(result.resultCode, equals(0));

    // Search for the added entry

    var filter = Filter.equals("ou", branchOU);
    var searchAttrs = ["ou", "description"];

    var count = 0;

    await for (SearchEntry entry
        in ldap.search(baseDN.dn, filter, searchAttrs).stream) {
      expect(entry, isNotNull);

      var ouSet = entry.attributes["ou"];
      expect(ouSet, isNotNull);
      expect(ouSet.values.length, equals(1));
      expect(ouSet.values.first, equals(branchOU));

      var descSet = entry.attributes["description"];
      expect(descSet, isNotNull);
      expect(descSet.values.length, equals(1));
      expect(descSet.values.first, equals(branchDescription));

      expect(entry.attributes.length, equals(2)); // no other attributes

      count++;
    }

    expect(count, equals(1));
  });

  //----------------

  test("adding an entry that already exists fails", () async {
    // Add the People organizationalUnit entry

    var result = await ldap.add(branchDN.dn, branchAttrs);
    assert(result.resultCode == 0);

    // Try to add another entry with the same DN

    var newDescription = "New description should not get used";

    var newAttrs = {
      "objectclass": ["organizationalUnit"],
      "description": newDescription
    };

    expect(newDescription, isNot(equals(branchDescription)));

    // Attempt to add an entry with the same DN

    expect(ldap.add(branchDN.dn, newAttrs),
        throwsA(new isInstanceOf<LDAPResult>()));

    // The original entry is present and unchanged

    var filter = Filter.equals("ou", branchOU);
    var searchAttrs = ["description", "ou"]; // also tests order does not matter

    var count = 0;

    await for (SearchEntry entry
        in ldap.search(baseDN.dn, filter, searchAttrs).stream) {
      expect(entry, isNotNull);

      var ouSet = entry.attributes["ou"];
      expect(ouSet, isNotNull);
      expect(ouSet.values.length, equals(1));
      expect(ouSet.values.first, equals(branchOU));

      var descSet = entry.attributes["description"];
      expect(descSet, isNotNull);
      expect(descSet.values.length, equals(1));
      expect(descSet.values.first, equals(branchDescription)); // unchanged

      expect(entry.attributes.length, equals(2)); // no other attributes

      count++;
    }

    expect(count, equals(1));
  });

  //----------------

  test("adding a person entry", () async {
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

  test("adding an entry under non-existant entry fails", () async {
    // Attempt to add the test person (without first adding the branch entry)

    expect(ldap.add(testPersonDN.dn, testPersonAttrs),
        throwsA(new isInstanceOf<LDAPResult>()));
  });

  //----------------

  test("adding an entry with missing mandatory attribute fails", () async {
    // Add the branch entry

    var result1 = await ldap.add(branchDN.dn, branchAttrs);
    assert(result1.resultCode == 0);

    // Attempt to add the test person missing a mandatory attribute

    final attrsMissingMandatory = {
      "objectclass": ["person"],
      "description": "Test person"
      // no "sn" attribute, which is mandatory in the "person" schema
    };

    expect(ldap.add(testPersonDN.dn, attrsMissingMandatory),
        throwsA(new isInstanceOf<LDAPResult>()));
  });
}

//================================================================

main() {
  group("LDAP", () => doTests("test-LDAP"));

  // group("LDAPS", () => doTest("test-LDAPS")); // uncomment to test with LDAPS
}
