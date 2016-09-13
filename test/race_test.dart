// Tests potential race conditions.
//
//----------------------------------------------------------------

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:dart_config/default_server.dart' as config_file;

import 'package:dartdap/dartdap.dart';

//----------------------------------------------------------------

const String testConfigFile = "test/TEST-config.yaml";

// Enable logging by setting to true.

const bool doLogging = false;

//----------------------------------------------------------------

var testDN = new DN("dc=example,dc=com");

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

  var gotNoResults = false;

  try {
    await for (SearchEntry entry in searchResults.stream) {
      expect(entry, isNotNull);
      expect(entry, new isInstanceOf<SearchEntry>());
    }
  } on LdapResultNoSuchObjectException {
    gotNoResults = true;
  } catch (e) {
    print("Caught exception: $e (${e.runtimeType})");
    expect(false, isTrue); // should not reach here
  }

  expect(gotNoResults, isTrue);
}

//----------------------------------------------------------------

var NUM_OPEN_CLOSE = 8;
var NUM_CYCLES = 4;

main() async {
  // Create two connections from parameters in the config file

  var p = (await config_file.loadConfig(testConfigFile))["test-LDAP"];
  assert(p["ssl"] == null || p["ssl"] == false);

  var s = (await config_file.loadConfig(testConfigFile))["test-LDAPS"];
  assert(s["ssl"] == true);

  if (doLogging) {
    //  startQuickLogging();
    hierarchicalLoggingEnabled = true;

    Logger.root.onRecord.listen((LogRecord rec) {
      print(
          '${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec.message}');
    });

    Logger.root.level = Level.OFF;

    new Logger("ldap").level = Level.INFO;
    new Logger("ldap.connection").level = Level.INFO;
    new Logger("ldap.send.ldap").level = Level.INFO;
    new Logger("ldap.send.bytes").level = Level.INFO;
    new Logger("ldap.recv.bytes").level = Level.INFO;
    new Logger("ldap.recv.asn1").level = Level.INFO;
  }

  //================================================================

  group("Race condition", () {
    //----------------------------------------------------------------

    test("multiple opens", () async {
      var ldap = new LdapConnection(
          host: p["host"], ssl: p["ssl"], port: p["port"], autoConnect: true);

      expect(ldap.state, equals(ConnectionState.closed));
      expect(ldap.isAuthenticated, isFalse);

      var pending = new List<Future>();

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
      var ldap = new LdapConnection(
          host: p["host"], ssl: p["ssl"], port: p["port"], autoConnect: true);

      expect(ldap.state, equals(ConnectionState.closed));
      expect(ldap.isAuthenticated, isFalse);

      await ldap.open();

      expect(ldap.state, equals(ConnectionState.ready));
      expect(ldap.isAuthenticated, isFalse);

      // LDAP operations can be performed on an open connection

      await doLdapOperation(ldap);

      // Close the connection

      var pending = new List<Future>();

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
