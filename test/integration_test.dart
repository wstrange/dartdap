// Example of how to perform LDAP operations.
//
//----------------------------------------------------------------

import 'package:test/test.dart';
import 'package:logging/logging.dart';
import 'package:dart_config/default_server.dart' as config_file;

import 'package:dartdap/dartdap.dart';

//----------------------------------------------------------------

const String testConfigFile = "test/TEST-config.yaml";

/// Set to true to not clean up LDAP directory after test runs.
///
const bool KEEP_ENTRIES_FOR_DEBUGGING = false;

//----------------------------------------------------------------

void doTests(String configName) {
  // Normally, unit tests open the LDAP connection in the [setUp]
  // and close the connection in the [tearDown] functions.
  // Since this integration test demonstrates how the LDAP package
  // is used in a real application, everything is done inside the
  // test instead of using setUp/tearDown functions.

  test('add/modify/search/delete', () async {
    //----------------
    // Create the connection (at the start of the test)

    LdapConnection ldap;

    if (configName != null) {
      // For testing purposes, load connection parameters from the
      // configName section of a config file.

      var c = (await config_file.loadConfig(testConfigFile))[configName];
      ldap = new LdapConnection(
          host: c["host"],
          ssl: c["ssl"],
          port: c["port"],
          bindDN: c["bindDN"],
          password: c["password"]);
      //await ldap.open();
      //await ldap.bind();
    } else {
      // Or the connection parameters can be explicitly specified in code.
      ldap = new LdapConnection(host: "localhost");
      ldap.setProtocol(false, 10389);
      await ldap.setAuthentication("cn=Manager,dc=example,dc=com", "p@ssw0rd");
      //await ldap.open();
      //await ldap.bind();
    }

    //----------------
    // The distinguished name is a String value

    var engineeringDN = "ou=Engineering,dc=example,dc=com";
    var salesDN = "ou=Sales,dc=example,dc=com";
    var businessDevelopmentDN = "ou=Business Development,dc=example,dc=com";
    var supportDN = "ou=Support,ou=Engineering,dc=example,dc=com";

    // For testing purposes, make sure entries do not exist before proceeding.

    for (var dn in [engineeringDN, salesDN, businessDevelopmentDN, supportDN]) {
      try {
        await ldap.delete(dn);
      } on LdapResultNoSuchObjectException catch (_) {
        // Ignore these exceptions, since the entry normally does not exist to be deleted
      }
    }

    //----
    // Add the entries

    var attrs = {
      "objectClass": ["organizationalUnit"],
      "description": "Example organizationalUnit entry"
    };

    var result = await ldap.add(engineeringDN, attrs);
    expect(result.resultCode, equals(0),
        reason: "Could not add engineering entry");

    result = await ldap.add(salesDN, attrs);
    expect(result.resultCode, equals(0), reason: "Could not add sales entry");

    //----
    // Modify: change attribute values

    var mod1 =
        new Modification.replace("description", ["Engineering department"]);
    result = await ldap.modify(engineeringDN, [mod1]);
    expect(result.resultCode, equals(0),
        reason: "could not change engineering description attribute");

    var mod2 = new Modification.replace(
        "description", ["Sales department", "Business development department"]);
    result = await ldap.modify(salesDN, [mod2]);
    expect(result.resultCode, equals(0),
        reason: "Could not change sales description attribute");

    //----
    // Modify: rename

    /* TODO: For some reason OUD does not seem to respect the deleteOldRDN flag
        It always moves the entry - and does not leave the old one
     */

    var tmpRDN = "ou=Business Development";
    var r = await ldap.modifyDN(
        salesDN, tmpRDN); // rename "Sales" to "Business Development"
    expect(r.resultCode, equals(0), reason: "Could not rename sales entry");

    // Modify: rename and change parent
    //
    //   true = delete old RDN
    //   engineeringDN = new parent

    /*
    TODO: get this working

    r = await ldap.modifyDN(
        businessDevelopmentDN, "ou=Support", true, engineeringDN);
    expect(r.resultCode, equals(0),
        reason: "Could not change Business Development to Support");
    */

    //----
    // Compare

    r = await ldap.compare(
        engineeringDN, "description", "ENGINEERING DEPARTMENT");
    expect(r.resultCode, equals(ResultCode.COMPARE_TRUE),
        reason: "Compare failed");

    //----------------
    // Search

    var baseDN = "dc=example,dc=com";
    var queryAttrs = ["ou", "objectClass"];
    var filter = Filter.equals("ou", "Engineering");

    //TODO:  ldap.onError = expectAsync((e) => expect(false, 'Should not be reached'), count: 0);

    // ou=Engineering

    int numFound = 0;
    var searchResult = await ldap.search(baseDN, filter, queryAttrs);
    await for (var entry in searchResult.stream) {
      expect(entry, new isInstanceOf<SearchEntry>());
      numFound++;
    }
    expect(numFound, equals(1),
        reason: "Unexpected number of entries in (ou=Engineering)");

    /*
    // not(ou=Engineering)

    var notFilter = Filter.not(filter);

    numFound = 0;
    await for (var entry
        in ldap.search("dc=example,dc=com", notFilter, queryAttrs).stream) {
      expect(entry, new isInstanceOf<SearchEntry>());
      numFound++;
    }
    expect(numFound, equals(1),
        reason:
            "Did not find expected number of entries in (not(ou=Engineering))");
            */

    //----
    // Delete the entries

    if (!KEEP_ENTRIES_FOR_DEBUGGING) {
      result = await ldap.delete(businessDevelopmentDN);
      expect(result.resultCode, equals(0),
          reason: "Could not delete business development entry");

      result = await ldap.delete(engineeringDN);
      expect(result.resultCode, equals(0),
          reason: "Could not delete engineering entry");
    }

    //----
    // Deleting a non-existent entry will raise an exception

    var deleteFailed = false;
    try {
      await ldap.delete(salesDN);
      fail("Delete should not have succeeded: $salesDN");
    } on LdapResultNoSuchObjectException catch (_) {
      deleteFailed = true;
    }
    expect(deleteFailed, isTrue);

    //----
    // Close the connection

    await ldap.close();
  });
}

//----------------------------------------------------------------
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
  //new Logger("ldap").level = Level.OFF;
  //new Logger("ldap.connection").level = Level.OFF;
  //new Logger("ldap.recv").level = Level.OFF;
  //new Logger("ldap.recv.ldap").level = Level.OFF;
  //new Logger("ldap.send").level = Level.OFF;
  //new Logger("ldap.recv.ldap").level = Level.OFF;
  //new Logger("ldap.recv.asn1").level = Level.OFF;
  //new Logger("ldap.recv.bytes").level = Level.OFF;
}

//----------------------------------------------------------------

void main() {
  //setupLogging();

  group("LDAP", () => doTests("test-LDAP"));
  group("LDAPS", () => doTests("test-LDAPS"));
  group("LDAP (connection parameters in code)", () => doTests(null));
}
