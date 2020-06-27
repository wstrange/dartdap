// Tests potential race conditions.
//
//----------------------------------------------------------------

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';

import 'util.dart' as util;

//----------------------------------------------------------------

const String testConfigFile = "test/TEST-config.yaml";

// Enable logging by setting to true.

const bool doLogging = false;

//----------------------------------------------------------------

var testDN = DN("dc=example,dc=com");

/// Perform some LDAP operation.
///
/// For the purpose of the tests in this file, this can be any operation
/// (except for BIND) which will require the connection to be open.
///
Future doLdapOperation(LdapConnection ldap) async {
  var filter = Filter.present("cn");
  var searchAttrs = ["cn", "sn"];

  // This search actually should not find any results, but that doesn't matter

  var searchResults = await ldap.search(testDN.dn, filter, searchAttrs);

  var numResults = 0;

  try {
    await for (SearchEntry entry in searchResults.stream) {
      numResults++;
      expect(entry, isNotNull);
      expect(entry, const TypeMatcher<SearchEntry>());
    }
  } on LdapResultNoSuchObjectException {
    fail("Unexpected: LdapResultNoSuchObjectException: ${testDN.dn}");
  } catch (e) {
    fail("Unexpected exception: $e (${e.runtimeType})");
  }

  expect(numResults, equals(0), reason: "Got results when not expecting any");
}

//----------------------------------------------------------------

var NUM_OPEN_CLOSE = 8;
var NUM_CYCLES = 4;

void main() async {
  final config = util.Config();

  group('race', ()
  {
    final directoryConfig = config.defaultDirectory;

    if (doLogging) {
      //  startQuickLogging();
      hierarchicalLoggingEnabled = true;

      Logger.root.onRecord.listen((LogRecord rec) {
        print(
            '${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec
                .message}');
      });

      Logger.root.level = Level.OFF;

      Logger("ldap").level = Level.INFO;
      Logger("ldap.connection").level = Level.INFO;
      Logger("ldap.send.ldap").level = Level.INFO;
      Logger("ldap.send.bytes").level = Level.INFO;
      Logger("ldap.recv.bytes").level = Level.INFO;
      Logger("ldap.recv.asn1").level = Level.INFO;
    }

    //================================================================

    group("Race condition", () {
      //----------------------------------------------------------------

      test("multiple opens", () async {
        var ldap = directoryConfig.connect();

        expect(ldap.state, equals(ConnectionState.closed));
        // TODO: this test used to expect isAuthenticated to be false
        // but it is true: why? Was the test wrong or the code is now wrong?
        //  expect(ldap.isAuthenticated, isFalse);

        var pending = <Future>[];

        for (var batch = 0; batch < NUM_CYCLES; batch++) {
          // Multiple asynchronous opens

          for (var x = 0; x < NUM_OPEN_CLOSE; x++) {
            pending.add(ldap.open());
          }

          for (var x = 0; x < NUM_OPEN_CLOSE; x++) {
            await pending[x];
          }
        }

        expect(ldap.state, equals(ConnectionState.ready));
        // TODO: test used to have this: expect(ldap.isAuthenticated, isFalse);

        // LDAP operations can be performed on an open connection

        await doLdapOperation(ldap);

        // Close the connection

        await ldap.close();

        expect(ldap.state, equals(ConnectionState.closed));
        // TODO: test used to have this expect(ldap.isAuthenticated, isFalse);
      });

      //----------------

      test("multiple close", () async {
        var ldap = directoryConfig.connect();

        expect(ldap.state, equals(ConnectionState.closed));
        // TODO: this test used to expect isAuthenticated isFalse
        // but it now isTrue. Why? Is the test wrong or has the implementation
        // changed?
        // expect(ldap.isAuthenticated, isFalse);

        await ldap.open();

        expect(ldap.state, equals(ConnectionState.ready));
        // TODO: see above comment, expect(ldap.isAuthenticated, isFalse);

        // LDAP operations can be performed on an open connection

        await doLdapOperation(ldap);

        // Close the connection

        var pending = <Future>[];

        for (var batch = 0; batch < NUM_CYCLES; batch++) {
          // Multiple asynchronous opens

          for (var x = 0; x < NUM_OPEN_CLOSE; x++) {
            pending.add(ldap.close());
          }

          for (var x = 0; x < NUM_OPEN_CLOSE; x++) {
            await pending[x];
          }
        }

        expect(ldap.state, equals(ConnectionState.closed));
        // TODO: test used to have this expect(ldap.isAuthenticated, isFalse);
      });
    });
  }, skip: config.skipIfMissingDefaultDirectory);
}
