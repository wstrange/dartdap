// Tests searching for entries from the LDAP directory.
//
// Depends on add and delete working.
//
//----------------------------------------------------------------

import 'dart:async';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import 'util.dart' as util;

//----------------------------------------------------------------

const String descriptionStr = "Test people branch";

const int NUM_ENTRIES = 3;

//----------------------------------------------------------------
// Create entries needed for testing.

Future populateEntries(LdapConnection ldap, DN testDN) async {
  // Create entry

  var addResult = await ldap.add(testDN.dn, {
    "objectclass": ["organizationalUnit"],
    "description": descriptionStr
  });
  assert(addResult is LdapResult);
  assert(addResult.resultCode == 0);

  // Create subentries

  for (var j = 0; j < NUM_ENTRIES; ++j) {
    var attrs = {
      "objectclass": ["inetorgperson"],
      "sn": "User $j"
    };
    var addResult = await ldap.add(testDN.concat("cn=user$j").dn, attrs);
    assert(addResult is LdapResult);
    assert(addResult.resultCode == 0);
  }
}

//----------------------------------------------------------------
/// Clean up before/after testing.

Future purgeEntries(LdapConnection ldap, DN testDN) async {
  // Delete subentries

  for (var j = 0; j < NUM_ENTRIES; ++j) {
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

void runTests(util.ConfigDirectory configDirectory) {
  LdapConnection ldap;
  DN testDN;

  //----------------

  setUp(() async {
    testDN = configDirectory.testDN.concat("ou=People");

    ldap = configDirectory.connect();
    await purgeEntries(ldap, testDN);
    await populateEntries(ldap, testDN);
  });

  //----------------

  tearDown(() async {
    await purgeEntries(ldap, testDN);
    await ldap.close();
  });

  //----------------
  // Searches for cn=user0 under ou=People

  test("search with filter: equals attribute in DN", () async {
    var filter = Filter.equals("cn", "user0");
    var searchAttrs = ["cn", "sn"];

    var count = 0;

    var searchResults = await ldap.search(testDN.dn, filter, searchAttrs);
    await for (SearchEntry entry in searchResults.stream) {
      expect(entry, isNotNull);

      var cnSet = entry.attributes["cn"];
      expect(cnSet, isNotNull);
      expect(cnSet.values.length, equals(1));
      expect(cnSet.values.first, equals("user0"));

      var descSet = entry.attributes["sn"];
      expect(descSet, isNotNull);
      expect(descSet.values.length, equals(1));
      expect(descSet.values.first, equals("User 0"));

      expect(entry.attributes.length, equals(2)); // no other attributes

      count++;
    }

    expect(count, equals(1), reason: "Unexpected number of entries");
  });

  //----------------
  // Searches for sn="User 1" under ou=People under the testDN

  test("search with filter: equals attribute not in DN", () async {
    var filter = Filter.equals("sN", "uSeR 1"); // Note: sn is case-insensitve
    var searchAttrs = ["cn", "sn"];

    var count = 0;

    var searchResults = await ldap.search(testDN.dn, filter, searchAttrs);
    await for (SearchEntry entry in searchResults.stream) {
      expect(entry, isNotNull);

      var cnSet = entry.attributes["cn"];
      expect(cnSet, isNotNull, reason: "Requested attribute not found");
      expect(cnSet.values.length, equals(1));
      expect(cnSet.values.first, equals("user1"));

      var descSet = entry.attributes["sn"];
      expect(descSet, isNotNull, reason: "Requested attribute not found");
      expect(descSet.values.length, equals(1));
      expect(descSet.values.first, equals("User 1"));

      expect(entry.attributes.length, equals(2)); // no other attributes

      count++;
    }

    expect(count, equals(1), reason: "Unexpected number of entries");
  });

  //----------------
  // Searches for cn is present under ou=People under testDN

  test("search with filter: present", () async {
    var filter = Filter.present("cn");
    var searchAttrs = ["cn", "sn"];

    var count = 0;

    var searchResults = await ldap.search(testDN.dn, filter, searchAttrs);
    await for (SearchEntry entry in searchResults.stream) {
      expect(entry, isNotNull);
      expect(entry, const TypeMatcher<SearchEntry>());

      var cnSet = entry.attributes["cn"];
      expect(cnSet, isNotNull);
      expect(cnSet.values.length, equals(1));
      expect(cnSet.values.first, startsWith("user"));

      var descSet = entry.attributes["sn"];
      expect(descSet, isNotNull);
      expect(descSet.values.length, equals(1));
      expect(descSet.values.first, startsWith("User "));

      expect(entry.attributes.length, equals(2)); // no other attributes

      count++;
    }

    expect(count, equals(NUM_ENTRIES), reason: "Unexpected number of entries");
  });

  //----------------

  test("search with filter: substring", () async {
    var filter = Filter.substring("cn", "uS*"); // note: cn is case-insensitive
    var searchAttrs = ["cn"];

    var count = 0;

    var searchResults = await ldap.search(testDN.dn, filter, searchAttrs);
    await for (SearchEntry entry in searchResults.stream) {
      expect(entry, isNotNull);
      expect(entry, const TypeMatcher<SearchEntry>());

      var cnSet = entry.attributes["cn"];
      expect(cnSet, isNotNull);
      expect(cnSet.values.length, equals(1));
      expect(cnSet.values.first, startsWith("user"));

      expect(entry.attributes.length, equals(1)); // no other attributes

      count++;
    }

    expect(count, equals(NUM_ENTRIES), reason: "Unexpected number of entries");
  });

  //----------------

  test("search from non-existent entry", () async {
    var filter = Filter.equals("ou", "People");
    var searchAttrs = ["ou", "description"];

    var count = 0;
    var gotException = false;

    try {
      var searchResults = await ldap.search(
          configDirectory.testDN.concat('ou=NoSuchEntry').dn,
          filter,
          searchAttrs);
      // ignore: unused_local_variable
      await for (SearchEntry entry in searchResults.stream) {
        fail("Unexpected result from search under non-existant entry");
      }
    } on LdapResultNoSuchObjectException catch (e) {
      // todo: WS Update
      print(e);
      //expect(e.result.matchedDN, equals(testDN.dn)); // part that did match
      gotException = true;
    } catch (e) {
      expect(e, const TypeMatcher<LdapException>());
      fail("Unexpected exception: $e");
    }

    expect(count, equals(0), reason: "Unexpected number of entries");
    expect(gotException, isTrue);
  });
}

//----------------------------------------------------------------

void main() {
  final config = util.Config();

  group('tests', () {
    runTests(config.defaultDirectory);
  }, skip: config.skipIfMissingDefaultDirectory);

  group('tests over LDAPS', () {
    runTests(config.directory(util.ldapsDirectoryName));
  }, skip: config.skipIfMissingDirectory(util.ldapsDirectoryName));
}
