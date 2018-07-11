// Tests the API under load.
//
//----------------------------------------------------------------

import 'dart:async';
import 'dart:io';

import 'package:dart_config/default_server.dart' as config_file;
import 'package:logging/logging.dart';
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
  "description": branchDescription,
};

// The LDAP directory being used for testing must have a size limit greater
// than or equal to this value (or no size limit) for these tests to succeed.

const int DIRECTORY_MIN_SIZE_LIMIT = 1000;

// The number of entries to use for the load tests

const int NUM_ENTRIES = 10; // 256

const String cnPrefix = "user";

//----------------------------------------------------------------
// Create entries needed for testing.

Future populateEntries(LdapConnection ldap) async {
  var addResult = await ldap.add(branchDN.dn, branchAttrs);
  assert(addResult is LdapResult);
  assert(addResult.resultCode == 0);
}

//----------------------------------------------------------------

/// Purge entries from the test to clean up

Future purgeEntries(LdapConnection ldap) async {
  // Purge the bulk person entries

  for (int j = NUM_ENTRIES - 1; 0 <= j; j--) {
    try {
      await ldap.delete(branchDN.concat("cn=$cnPrefix$j").dn);
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
  var ldap;

  //----------------

  setUp(() async {
    var c = (await config_file.loadConfig(testConfigFile))[configName];
    ldap = new LdapConnection(
        host: c["host"],
        ssl: c["ssl"],
        port: c["port"],
        bindDN: c["bindDN"],
        password: c["password"],
        badCertificateHandler: (X509Certificate _) => true);
    // Note: setting badCertificateHandler to accept test certificate

    //await ldap.open();
    //await ldap.bind();

    await ldap.open(); // optional step: makes log entries more sensible
    await purgeEntries(ldap);
    await populateEntries(ldap);
  });

  //----------------

  tearDown(() async {
    await purgeEntries(ldap);
    await ldap.close();
  });

  //----------------

  test("initial", () async {
    var numToCreate = 10;
    var sizeLimit = 5;

    expect(numToCreate, lessThanOrEqualTo(DIRECTORY_MIN_SIZE_LIMIT));
    expect(sizeLimit, lessThanOrEqualTo(numToCreate));
  });
/*
  //----------------

  test("add/search/delete under load with $NUM_ENTRIES entries", () async {

    var loggerMain = new Logger("main");

    expect(NUM_ENTRIES, lessThanOrEqualTo(DIRECTORY_MIN_SIZE_LIMIT));

    // Bulk add

    loggerMain.fine("add");

    for (int x = 0; x < NUM_ENTRIES; x++) {
      var attrs = {
        "objectclass": ["inetorgperson"],
        "sn": "User $x",
        "displayName": "Test User $x",
        "givenName": "John",
        "mail": "user$x@example.com",
        "employeeType": "test",
        "employeeNumber": "$x",
      };
      var result = await ldap.add(branchDN.concat("cn=$cnPrefix$x").dn, attrs);
      expect(result.resultCode, equals(0));
    }

    // Bulk search

    var filter = Filter.substring("cn=${cnPrefix}*");

    var attrs = [
      "cn",
      "sn",
      "givenName",
      "displayName",
      "mail",
      "employeeType",
      "employeeNumber"
    ];


    loggerMain.fine("search");

    var count = 0;

    var searchResults = await ldap.search(branchDN.dn, filter, attrs);
    await for (SearchEntry entry in searchResults.stream) {
      expect(entry, isNotNull);

      var cnSet = entry.attributes["cn"];
      expect(cnSet, isNotNull);
      expect(cnSet.values.length, equals(1));
      expect(cnSet.values.first, startsWith(cnPrefix));

      // Other attributes
      expect(entry.attributes.length, equals(attrs.length));

      count++;
    }

    expect(count, equals(NUM_ENTRIES), reason: "Unexpected number of entries");

    loggerMain.fine("delete");

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

  //----------------

  test("sizeLimit", () async {
    var numToCreate = 10;
    var sizeLimit = 5;

    expect(numToCreate, lessThanOrEqualTo(DIRECTORY_MIN_SIZE_LIMIT));
    expect(sizeLimit, lessThanOrEqualTo(numToCreate));

    // Bulk add

    for (int x = 0; x < numToCreate; x++) {
      var attrs = {
        "objectclass": ["inetorgperson"],
        "sn": "User $x",
        "displayName": "Test User $x",
        "givenName": "John",
        "mail": "user$x@example.com",
        "employeeType": "test",
        "employeeNumber": "$x",
      };
      var result = await ldap.add(branchDN.concat("cn=$cnPrefix$x").dn, attrs);
      expect(result.resultCode, equals(0));
    }

    // Search with sizeLimit

    var filter = Filter.substring("cn=${cnPrefix}*");

    var attrs = [
      "cn",
      "sn",
      "givenName",
      "displayName",
      "mail",
      "employeeType",
      "employeeNumber"
    ];

    var count = 0;

    // Size limit

    var searchResults =
    await ldap.search(branchDN.dn, filter, attrs, sizeLimit: sizeLimit);
    var entriesRetrieved = 0;
    try {
      await for (SearchEntry entry in searchResults.stream) {
        expect(entry, isNotNull);
        entriesRetrieved++;
      }
      fail("sizeLimit should have been triggered");
    } catch (e) {
      expect(e, const TypeMatcher<LdapResultSizeLimitExceededException>());
      // Note: server might have a lower size limit set
      expect(entriesRetrieved, lessThanOrEqualTo(sizeLimit),
          reason: "search returned more than sizeLimit entries");
    }

    // Delete

    for (int x = 0; x < numToCreate; x++) {
      await ldap.delete(branchDN.concat("cn=$cnPrefix$x").dn);
    }
  }, timeout: new Timeout(new Duration(minutes: 5)));
  */
}

//================================================================

void setupLogging() {
  const bool doLogging = false; // Enable logging by setting to true.

  if (doLogging) {
    //  startQuickLogging();
    hierarchicalLoggingEnabled = true;

    Logger.root.onRecord.listen((LogRecord rec) {
      print(
          '${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec.message}');
    });

    Logger.root.level = Level.OFF;

    new Logger("ldap").level = Level.INFO;
    new Logger("ldap.connection").level = Level.ALL;
    new Logger("ldap.send.ldap").level = Level.INFO;
    new Logger("ldap.send.bytes").level = Level.INFO;
    new Logger("ldap.recv.bytes").level = Level.INFO;
    new Logger("ldap.recv.asn1").level = Level.INFO;
    new Logger("main").level = Level.INFO;
  }
}

//----------------------------------------------------------------

main() {
  setupLogging();

  group("LDAP", () => doTests("test-LDAP"));

  group("LDAPS", () => doTests("test-LDAPS"));
}
