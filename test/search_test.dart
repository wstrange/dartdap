// Tests searching for entries from the LDAP directory.
//
// Depends on add and delete working.
//
//----------------------------------------------------------------

import 'dart:async';

import 'package:dart_config/default_server.dart' as config_file;
import 'package:test/test.dart';
import 'package:logging/logging.dart';

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

Future populateEntries(LdapConnection ldap) async {
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

Future purgeEntries(LdapConnection ldap) async {
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
  var ldap;

  //----------------

  setUp(() async {
    var c = (await config_file.loadConfig(testConfigFile))[configName];
    ldap = new LdapConnection(
        host: c["host"],
        ssl: c["ssl"],
        port: c["port"],
        bindDN: c["bindDN"],
        password: c["password"]);

    await purgeEntries(ldap);
    await populateEntries(ldap);
  });

  //----------------

  tearDown(() async {
    await purgeEntries(ldap);
    await ldap.close();
  });

  //----------------
  // Searches for cn=user0 under ou=People,dc=example,dc=com

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
  // Searches for sn="User 1" under ou=People,dc=example,dc=com

  test("search with filter: equals attribute not in DN", () async {
    var filter = Filter.equals("sN", "uSeR 1"); // Note: sn is case-insensitve
    var searchAttrs = ["cN", "sN"];

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
  // Searches for cn is present under ou=People,dc=example,dc=com

  test("search with filter: present", () async {
    var filter = Filter.present("cn");
    var searchAttrs = ["cn", "sn"];

    var count = 0;

    var searchResults = await ldap.search(testDN.dn, filter, searchAttrs);
    await for (SearchEntry entry in searchResults.stream) {
      expect(entry, isNotNull);
      expect(entry, new isInstanceOf<SearchEntry>());

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
    var filter = Filter.substring("cn=uS*"); // note: cn is case-insensitive
    var searchAttrs = ["cn"];

    var count = 0;

    var searchResults = await ldap.search(testDN.dn, filter, searchAttrs);
    await for (SearchEntry entry in searchResults.stream) {
      expect(entry, isNotNull);
      expect(entry, new isInstanceOf<SearchEntry>());

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

  test("search from non-existant entry", () async {
    var filter = Filter.equals("ou", "People");
    var searchAttrs = ["ou", "description"];

    var count = 0;
    var gotException = false;

    try {
      var searchResults = await ldap.search(
          "ou=NoSuchEntry,dc=example,dc=com", filter, searchAttrs);
      await for (SearchEntry entry in searchResults.stream) {
        fail("Unexpected result from search under non-existant entry");
        expect(entry, isNotNull);
        count++;
      }
    } catch (e) {
      expect(e, new isInstanceOf<LDAPResult>());
      expect(e.resultCode, equals(ResultCode.NO_SUCH_OBJECT));
      gotException = true;
    }

    expect(count, equals(0), reason: "Unexpected number of entries");
    expect(gotException, isTrue);
  });
}

//================================================================

/// Setup logging
///
/// Change the values in this function to change the level of logging
/// that is done during debugging.
///
/// Note: the default for the root level logger is Level.INFO, so if
/// no levels are set shout/severe/warning/info are logged, but
/// config/fine/finer/finest are not.
///
void setupLogging([Level commonLevel = Level.OFF]) {
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec.message}');
  });

  hierarchicalLoggingEnabled = true;

  // Normally, only change the values below:

  // Log level: an integer between 0 (ALL) and 2000 (OFF) or a string value:
  // "OFF", "SHOUT", "SEVERE", "WARNING", "INFO", "CONFIG", "FINE" "FINER",
  // "FINEST" or "ALL".

  //Logger.root.level = Level.OFF;
  //new Logger("ldap").level = Level.ALL;
  //new Logger("ldap.connection").level = Level.OFF;
  //new Logger("ldap.recv").level = Level.OFF;
  //new Logger("ldap.recv.ldap").level = Level.OFF;
  //new Logger("ldap.send").level = Level.OFF;
  //new Logger("ldap.recv.ldap").level = Level.OFF;
  //new Logger("ldap.recv.asn1").level = Level.OFF;
  //new Logger("ldap.recv.bytes").level = Level.OFF;
}

//----------------------------------------------------------------

main() {
  setupLogging();

  group("LDAP", () => doTest("test-LDAP"));

  // group("LDAPS", () => doTest("test-LDAPS")); // uncomment to test with LDAPS
}
