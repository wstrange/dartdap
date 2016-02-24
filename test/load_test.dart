// Tests the API under load.
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

const branchOU = "load_test";
const branchDescription = "Branch for $branchOU";

final branchDN = baseDN.concat("ou=$branchOU");
final branchAttrs = {
  "objectclass": ["organizationalUnit"],
  "description": branchDescription
};

const int NUM_ENTRIES = 2000;

//----------------------------------------------------------------
// Create entries needed for testing.

Future populateEntries(LDAPConnection ldap) async {
  var addResult = await ldap.add(branchDN.dn, branchAttrs);
  assert(addResult is LDAPResult);
  assert(addResult.resultCode == 0);
}

//----------------------------------------------------------------

/// Purge entries from the test to clean up

Future purgeEntries(LDAPConnection ldap) async {
  // Purge the bulk person entries

  for (int j = 0; j < NUM_ENTRIES; ++j) {
    try {
      await ldap.delete((branchDN.concat("cn=user$j")).dn);
    } catch (e) {
      // ignore any exceptions
    }
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
    await populateEntries(ldap);
  });

  //----------------

  tearDown(() async {
    await purgeEntries(ldap);
    await ldapConfig.close();
  });

  //----------------

  test("add/search/delete under load with $NUM_ENTRIES entries", () async {
    const cnPrefix = "user";

    // Bulk add

    for (int x = 0; x < NUM_ENTRIES; x++) {
      var attrs = {
        "objectclass": ["inetorgperson"],
        "sn": "Test User $x"
      };
      var result = await ldap.add(branchDN.concat("cn=$cnPrefix$x").dn, attrs);
      expect(result.resultCode, equals(0));
    }

    // Bulk search

    var filter = Filter.substring("cn=${cnPrefix}*");

    var attrs = ["cn"];

    var count = 0;

    // bit of a hack. Note the directory has a max limit
    // for the number of results returned. 1000 is the default for DJ
    //var expected = Math.min(NUM_ENTRIES, 1000);
    var expected =
        NUM_ENTRIES; // TODO: fix this to take into account directory max

    await for (SearchEntry entry
        in ldap.search(branchDN.dn, filter, attrs).stream) {
      expect(entry, isNotNull);

      var cnSet = entry.attributes["cn"];
      expect(cnSet, isNotNull);
      expect(cnSet.values.length, equals(1));
      expect(cnSet.values.first, startsWith(cnPrefix));

      expect(entry.attributes.length, equals(1)); // no other attributes

      count++;
    }

    expect(count, equals(expected), reason: "Unexpected number of entries");

    /*
              onError: (LDAPResult r) {
                if (r.resultCode == ResultCode.SIZE_LIMIT_EXCEEDED &&
                    count == expected) {
                  logger.info("got expected size result error $r");
                } else fail("Unexpected LDAP error $r");
              });
    });
     */

    // Bulk delete

    for (int x = 0; x < NUM_ENTRIES; x++) {
      await ldap.delete(branchDN.concat("cn=$cnPrefix$x").dn);
    }
  }, timeout: new Timeout(new Duration(minutes: 5)));
}

//================================================================

main() {
  group("LDAP", () => doTests("test-LDAP"));

  // group("LDAPS", () => doTests("test-LDAPS")); // uncomment to test with LDAPS
}
