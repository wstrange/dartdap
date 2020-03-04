// Tests potential race conditions.
//
//----------------------------------------------------------------

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'test_configuration.dart';
import 'package:dartdap/dartdap.dart';

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

main() async {
  // Create two connections from parameters in the config file

  var p = TestConfiguration(testConfigFile).connections["test-LDAP"];
  assert(p.ssl == false);

  var s = TestConfiguration(testConfigFile).connections["test-LDAPs"];
  assert(s.ssl == true);

  if (doLogging) {
    //  startQuickLogging();
    hierarchicalLoggingEnabled = true;

    Logger.root.onRecord.listen((LogRecord rec) {
      print(
          '${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec.message}');
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
      var ldap = LdapConnection(
          host: p.host, ssl: p.ssl, port: p.port);

      expect(ldap.state, equals(ConnectionState.closed));
      expect(ldap.isAuthenticated, isFalse);

      var pending = List<Future>();

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
      expect(ldap.isAuthenticated, isFalse);

      // LDAP operations can be performed on an open connection

      await doLdapOperation(ldap);

      // Close the connection

      await ldap.close();

      expect(ldap.state, equals(ConnectionState.closed));
      expect(ldap.isAuthenticated, isFalse);
    });

    //----------------

    test("multiple close", () async {
      var ldap = LdapConnection(
          host: p.host, ssl: p.ssl, port: p.port);

      expect(ldap.state, equals(ConnectionState.closed));
      expect(ldap.isAuthenticated, isFalse);

      await ldap.open();

      expect(ldap.state, equals(ConnectionState.ready));
      expect(ldap.isAuthenticated, isFalse);

      // LDAP operations can be performed on an open connection

      await doLdapOperation(ldap);

      // Close the connection

      var pending = List<Future>();

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
      expect(ldap.isAuthenticated, isFalse);
    });
  });
}
