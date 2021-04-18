// Example of how to perform LDAP operations.
//
//----------------------------------------------------------------

import 'package:dartdap/dartdap.dart';
import 'package:test/test.dart';

import 'util.dart' as util;

//----------------------------------------------------------------

/// Set to true to not clean up LDAP directory after test runs.
///
const bool KEEP_ENTRIES_FOR_DEBUGGING = false;

//----------------------------------------------------------------

void runTests(util.ConfigDirectory directoryConfig) {
  // Normally, unit tests open the LDAP connection in the [setUp]
  // and close the connection in the [tearDown] functions.
  // Since this integration test demonstrates how the LDAP package
  // is used in a real application, everything is done inside the
  // test instead of using setUp/tearDown functions.

  test('add/modify/search/delete', () async {
    //----------------
    // Create the connection (at the start of the test)

    var ldap = directoryConfig.getConnection();
    await ldap.open();
    await ldap.bind();

    //----------------
    // The distinguished name is a String value

    var engineeringDN = directoryConfig.testDN.concat('ou=Engineering').dn;
    var salesDN = directoryConfig.testDN.concat('ou=Sales').dn;
    var bisDevDN = directoryConfig.testDN.concat('ou=Business Development').dn;
    var supportDN = DN(engineeringDN).concat('ou=Support').dn;

    // For testing purposes, make sure entries do not exist before proceeding.

    for (var dn in [engineeringDN, salesDN, bisDevDN, supportDN]) {
      try {
        await ldap.delete(dn);
      } on LdapResultNoSuchObjectException catch (_) {
        // Ignore these exceptions, since the entry normally does not exist to be deleted
      }
    }

    //----
    // Add the entries

    var attrs = {
      'objectClass': ['organizationalUnit'],
      'description': 'Example organizationalUnit entry'
    };

    var result = await ldap.add(engineeringDN, attrs);
    expect(result.resultCode, equals(0),
        reason: 'Could not add engineering entry');

    result = await ldap.add(salesDN, attrs);
    expect(result.resultCode, equals(0), reason: 'Could not add sales entry');

    //----
    // Modify: change attribute values

    var mod1 = Modification.replace('description', ['Engineering department']);
    result = await ldap.modify(engineeringDN, [mod1]);
    expect(result.resultCode, equals(0),
        reason: 'could not change engineering description attribute');

    var mod2 = Modification.replace(
        'description', ['Sales department', 'Business development department']);
    result = await ldap.modify(salesDN, [mod2]);
    expect(result.resultCode, equals(0),
        reason: 'Could not change sales description attribute');

    //----
    // Modify: rename

    /* TODO: For some reason OUD does not seem to respect the deleteOldRDN flag
        It always moves the entry - and does not leave the old one
     */

    var tmpRDN = 'ou=Business Development';
    var r = await ldap.modifyDN(
        salesDN, tmpRDN); // rename 'Sales' to 'Business Development'
    expect(r.resultCode, equals(0), reason: 'Could not rename sales entry');

    // Modify: rename and change parent
    //
    //   true = delete old RDN
    //   engineeringDN = new parent

    /*
    TODO: get this working

    r = await ldap.modifyDN(
        businessDevelopmentDN, 'ou=Support', true, engineeringDN);
    expect(r.resultCode, equals(0),
        reason: 'Could not change Business Development to Support');
    */

    //----
    // Compare

    r = await ldap.compare(
        engineeringDN, 'description', 'ENGINEERING DEPARTMENT');
    expect(r.resultCode, equals(ResultCode.COMPARE_TRUE),
        reason: 'Compare failed');

    //----------------
    // Search

    var queryAttrs = ['ou', 'objectClass'];
    var filter = Filter.equals('ou', 'Engineering');

    //TODO:  ldap.onError = expectAsync((e) => expect(false, 'Should not be reached'), count: 0);

    // ou=Engineering

    var numFound = 0;
    var searchResult =
        await ldap.search(directoryConfig.testDN.dn, filter, queryAttrs);
    await for (var entry in searchResult.stream) {
      expect(entry, const TypeMatcher<SearchEntry>());
      numFound++;
    }
    expect(numFound, equals(1),
        reason: 'Unexpected number of entries in (ou=Engineering)');

    /*
    // not(ou=Engineering)

    var notFilter = Filter.not(filter);

    numFound = 0;
    await for (var entry
        in ldap.search(directoryConfig.testDN.dn, notFilter, queryAttrs).stream) {
      expect(entry, const TypeMatcher<SearchEntry>());
      numFound++;
    }
    expect(numFound, equals(1),
        reason:
            'Did not find expected number of entries in (not(ou=Engineering))');
            */

    //----
    // Delete the entries

    if (!KEEP_ENTRIES_FOR_DEBUGGING) {
      result = await ldap.delete(bisDevDN);
      expect(result.resultCode, equals(0),
          reason: 'Could not delete business development entry');

      result = await ldap.delete(engineeringDN);
      expect(result.resultCode, equals(0),
          reason: 'Could not delete engineering entry');
    }

    //----
    // Deleting a non-existent entry will raise an exception

    var deleteFailed = false;
    try {
      await ldap.delete(salesDN);
      fail('Delete should not have succeeded: $salesDN');
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

void main() {
  final config = util.Config();

  group('tests', () {
    runTests(config.defaultDirectory);
  }, skip: config.skipIfMissingDefaultDirectory);
}
