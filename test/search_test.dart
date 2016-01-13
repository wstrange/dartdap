// Tests searching for entries from the LDAP directory.
//
// Depends on add and delete working.
//
//----------------------------------------------------------------

import 'dart:async';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';


//----------------------------------------------------------------

const String testConfigFile = "test/TEST-config.yaml";

var baseDN = new DN("dc=example,dc=com");
var testDN = baseDN.concat("ou=People");
var nosuchDN = baseDN.concat("ou=NoSuchEntry");

const String descriptionStr = "Test people branch";

const int NUM_ENTRIES = 3;

//----------------------------------------------------------------
// Create entries needed for testing.

Future populateEntries(LDAPConnection ldap) async {
  // Create entry

  var addResult = await ldap.add(testDN.dn, {
    "objectclass": ["organizationalUnit"],
    "description": descriptionStr
  });
  assert(addResult is LDAPResult);
  assert(addResult.resultCode == 0);

  // Create subentries

  for (int j = 0; j < NUM_ENTRIES; ++j) {
    var attrs = {
      "objectclass": ["inetorgperson"],
      "sn": "User $j"
    };
    var addResult = await ldap.add(testDN.concat("cn=user$j").dn, attrs);
    assert(addResult is LDAPResult);
    assert(addResult.resultCode == 0);
  }
}

//----------------------------------------------------------------
/// Clean up before/after testing.

Future purgeEntries(LDAPConnection ldap) async {

  // Delete subentries

  for (int j = 0; j < NUM_ENTRIES; ++j) {
    try {
      await ldap.delete(testDN.concat("cn=user$j").dn);
    } catch (e) {
      // ignore any exceptions
    }
  }

  // Delete entry

  try {
    // this is designed to clean up any failed tests
    await ldap.delete(testDN.dn);
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

  test("search with single result", () async {
    var filter = Filter.equals("ou", "People");
    var searchAttrs = ["ou", "description"];

    var count = 0;

    await for (SearchEntry entry
        in ldap.search(baseDN.dn, filter, searchAttrs).stream) {
      expect(entry, isNotNull);

      var ouSet = entry.attributes["ou"];
      expect(ouSet, isNotNull);
      expect(ouSet.values.length, equals(1));
      expect(ouSet.values.first, equals("People"));

      var descSet = entry.attributes["description"];
      expect(descSet, isNotNull);
      expect(descSet.values.length, equals(1));
      expect(descSet.values.first, equals(descriptionStr));

      expect(entry.attributes.length, equals(2)); // no other attributes

      count++;
    }

    expect(count, equals(1));
  });

  //----------------

  test("search with multiple results", () async {

    // var filter = Filter.present("cn"); // TODO: fix this, bug?
    var filter = Filter.substring("cn=*");
    filter = Filter.equals("cn", "user0");
    var searchAttrs = ["cn"];

    var count = 0;

    await for (SearchEntry entry
    in ldap.search(testDN.dn, filter, searchAttrs).stream) {
      expect(entry, isNotNull);
      expect(entry, new isInstanceOf<SearchEntry>());

      var cnSet = entry.attributes["cn"];
      expect(cnSet, isNotNull);
      expect(cnSet.values.length, equals(1));
      expect(cnSet.values.first, startsWith("user"));

      expect(entry.attributes.length, equals(1)); // no other attributes

      count++;
    }

    expect(count, equals(NUM_ENTRIES));

  }, skip: "filters not working properly");

  //----------------

  test("search from non-existant entry", () async {
    var filter = Filter.equals("ou", "People");
    var searchAttrs = ["ou", "description"];

    var count = 0;
    var gotException = false;

    try {
      await for (SearchEntry entry
      in ldap
          .search("ou=NoSuchEntry,dc=example,dc=com", filter, searchAttrs)
          .stream) {
        fail("Unexpected result from search under non-existant entry");
        expect(entry, isNotNull);
        count++;
      }
    } catch (e) {
      expect(e, new isInstanceOf<LDAPResult>());
      expect(e.resultCode, equals(ResultCode.NO_SUCH_OBJECT));
      gotException = true;
    }

    expect(count, equals(0));
    expect(gotException, isTrue);
  });
}

//================================================================

main() {
  group("LDAP", () => doTest("test-LDAP"));

  // group("LDAPS", () => doTest("test-LDAPS")); // uncomment to test with LDAPS
}
