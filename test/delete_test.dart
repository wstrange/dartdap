// Tests deleting entries from the LDAP directory.
//
// Depends on add and search working.
//
//----------------------------------------------------------------

import 'dart:async';

import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import 'setup.dart';

//----------------------------------------------------------------

final branchOU = DN('ou=entry_delete_test');
final branchDescription = 'Branch for $branchOU';
final branchDN = branchOU + baseDN;

final branchAttrs = {
  'objectclass': ['organizationalUnit'],
  'description': branchDescription
};

// Test person

const testPersonCN = 'John Citizen'; // mandatory attribute (in person schema)
const testPersonSurname = 'Citizen'; // mandatory attribute
const testPersonDescription = 'Test person'; // optional attribute

final testPersonAttrs = {
  'objectclass': ['person'],
  'sn': testPersonSurname,
  'description': testPersonDescription
};

final baseDN = DN('dc=example,dc=com');

//----------------------------------------------------------------
// Create entries needed for testing.

Future populateEntries(LdapConnection ldap, DN branchDN, DN testPersonDN) async {
  var addResult = await ldap.add(branchDN, branchAttrs);
  assert(addResult.resultCode == 0);

  addResult = await ldap.add(testPersonDN, testPersonAttrs);
  assert(addResult.resultCode == 0);
}

//----------------------------------------------------------------
/// Clean up before/after testing.

Future purgeEntries(LdapConnection ldap, DN branchDN, DN testPersonDN) async {
  // Purge test person

  try {
    await ldap.delete(testPersonDN);
  } catch (e) {
    // ignore any exceptions thrown if entry does not exist
  }

  // Purge branch

  try {
    await ldap.delete(branchDN);
  } catch (e) {
    // ignore any exceptions if entry does not exist
  }
}

//----------------------------------------------------------------

void main() {
  late LdapConnection ldap;
  late DN testPersonDN;

  setUpAll(() async {
    ldap = defaultConnection();

    testPersonDN = DN('cn=$testPersonCN') + branchDN;
  });

  setUp(() async {
    await ldap.open();
    await ldap.bind();

    await purgeEntries(ldap, branchDN, testPersonDN);
    await populateEntries(ldap, branchDN, testPersonDN);
  });

  //----------------

  tearDown(() async {
    await purgeEntries(ldap, branchDN, testPersonDN);
    await ldap.close();
  });

  //----------------

  test('deleting an entry', () async {
    // Delete the entry

    var delResult = await ldap.delete(testPersonDN);
    expect(delResult, const TypeMatcher<LdapResult>());
    expect(delResult.resultCode, equals(0));

    // Search to check the entry is gone

    var filter = Filter.equals('cn', testPersonCN);
    var searchAttrs = ['ou'];

    var count = 0;

    var searchResults = await ldap.search(baseDN, filter, searchAttrs);
    await for (SearchEntry _ in searchResults.stream) {
      fail('Entry still exists after delete');
      // dead code
      //count++;
    }

    expect(count, equals(0));
  });

  //----------------

  test('deleting a non-existant entry raises an exception', () async {
    var nosuchDN = DN('cn=NoSuchPerson') + branchDN;

    try {
      await ldap.delete(nosuchDN);
      fail('exception not thrown');
    } catch (e) {
      expect(e, const TypeMatcher<LdapResultNoSuchObjectException>());
    }
  });

  //----------------

  test('deleting an entry with children raises an exception', () async {
    // Note: the test person entry is a child of the branch entry, so
    // the branch entry cannot be deleted.

    try {
      await ldap.delete(branchDN);
      fail('exception not thrown');
    } catch (e) {
      expect(e, const TypeMatcher<LdapResultNotAllowedOnNonleafException>());
    }
  });
}

//================================================================
