// Example of how to use the package.
//
//----------------------------------------------------------------

import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';

//----------------------------------------------------------------

const String testConfigFile = "test/TEST-config.yaml";

const bool KEEP_ENTRIES_FOR_DEBUGGING = false;

void doTests(String configName) {
  // Normally, unit tests open the LDAP connection in the setUp
  // and close the connection in the tearDown functions.
  // Since this integration test demonstrates how the LDAP package
  // is used in a real application, everything is done inside the
  // test instead of using setUp/tearDown functions.

  test('add/modify/search/delete', () async {
    //----------------
    // Create the connection (at the start of the test)

    LDAPConfiguration ldapConfig;
    LDAPConnection ldap;

    if (configName != null) {
      // For testing purposes, load connection parameters from the
      // configName section of a config file.
      ldapConfig = new LDAPConfiguration.fromFile(testConfigFile, configName);
    } else {
      // Or the connection parameters can be explicitly specified in code.
      ldapConfig = new LDAPConfiguration("localhost",
          port: 10389,
          ssl: false,
          bindDN: "cn=Manager,dc=example,dc=com",
          password: "p@ssw0rd");
    }

    // Establish a connection to the LDAP directory and bind to it
    ldap = await ldapConfig.getConnection();

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
      } on LDAPResult catch (e) {
        // Ignore any exceptions (i.e. thrown when the entry normally does not exist)
        assert(e.resultCode == ResultCode.NO_SUCH_OBJECT);
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

    var queryAttrs = ["ou", "objectClass"];

    //TODO:  ldap.onError = expectAsync((e) => expect(false, 'Should not be reached'), count: 0);

    // ou=Engineering

    var filter = Filter.equals("ou", "Engineering");

    int numFound = 0;
    await for (var entry
        in ldap.search("dc=example,dc=com", filter, queryAttrs).stream) {
      expect(entry, new isInstanceOf<SearchEntry>());
      numFound++;
    }
    expect(numFound, equals(1),
        reason: "Did not find expected number of entries in (ou=Engineering)");

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

    try {
      await ldap.delete(salesDN);
      fail("Delete should not have succeeded: $salesDN");
    } catch (e) {
      expect(e.resultCode, equals(ResultCode.NO_SUCH_OBJECT));
    }

    //----
    // Close the connection

    await ldapConfig.close();
  });
}

main() async {
  // Since this is a test, don't do any logging. But if logging is required,
  // you can use:
  //
  // startQuickLogging();

  group("LDAP", () => doTests("test-LDAP"));
  group("LDAPS", () => doTests("test-LDAPS"));
  group("LDAP (connection parameters in code)", () => doTests(null));
}
