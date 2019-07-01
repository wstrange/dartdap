// Tests connection open, close and bind.
//
//----------------------------------------------------------------

import 'dart:io';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import "util.dart" as util;
import 'package:matcher/mirror_matchers.dart';
import 'package:dartdap/dartdap.dart';

//----------------------------------------------------------------

const String testConfigFile = "test/TEST-config.yaml";


var badHost = "doesNotExist.example.com";
var badPort = 10999; // there must not be anything listing on this port

// Not all ldap servers allow anonymous search

var allowAnonymousSearch = false;
//----------------------------------------------------------------

var testDN = new DN("dc=example,dc=com");

/// Perform some LDAP operation.
///
/// For the purpose of the tests in this file, this can be any operation
/// (except for BIND) which will require the connection to be open.
///
FutureOr<void> doLdapOperation(LdapConnection ldap) async {

  if( ! allowAnonymousSearch )
    return;

  var filter = Filter.present("cn");
  var searchAttrs = ["cn", "sn"];

  // This search actually should not find any results, but that doesn't matter

  var searchResults = await ldap.search(testDN.dn, filter, searchAttrs, sizeLimit: 100);
  await for (SearchEntry entry in searchResults.stream) {
    expect(entry, isNotNull);
    expect(entry, const TypeMatcher<SearchEntry>());
  }
}

//----------------------------------------------------------------

main() async {
  // Create two connections from parameters in the config file

  var c = util.loadConfig(testConfigFile);
  var p = c["test-LDAP"];
  assert(p["ssl"] == null || p["ssl"] == false);

  var s = c["test-LDAPS"];
  assert(s["ssl"] == true);

  const bool doLogging = false;

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

  group("Manual mode", () {
    //----------------------------------------------------------------
    // Binding correctly

    group("connect succeeds", () {
      group("anonymous", () {
        test("using LDAP", () async {
          var ldap = new LdapConnection(
              host: p["host"], ssl: p["ssl"], port: p["port"]);
          await ldap.setAutomaticMode(false);

          expect(ldap.state, equals(ConnectionState.closed));
          expect(ldap.isAuthenticated, isFalse);
          expect(ldap.isAutomatic, isFalse);

          await ldap.open();

          expect(ldap.state, equals(ConnectionState.ready));
          expect(ldap.isAuthenticated, isFalse);

          await doLdapOperation(ldap);

          // Close the connection

          await ldap.close();

          expect(ldap.state, equals(ConnectionState.closed));
          expect(ldap.isAuthenticated, isFalse);

          // Open it again

          await ldap.open();

          expect(ldap.state, equals(ConnectionState.ready));
          expect(ldap.isAuthenticated, isFalse);

          // Redundant open. In manual mode (unlike in automatic mode) opening
          // an already open connection raises an exception. The invoker is
          // expected to track whether their connection is open or not.

          try {
            await ldap.open();
            expect(false, isTrue);
          } catch (e) {
            expect(e, const TypeMatcher<StateError>());
          }

          expect(ldap.state, equals(ConnectionState.ready));
          expect(ldap.isAuthenticated, isFalse);

          // Close it

          await ldap.close();

          expect(ldap.state, equals(ConnectionState.closed));
          expect(ldap.isAuthenticated, isFalse);

          // Closing an already closed connection is permitted, even though
          // it does nothing.

          await ldap.close();

          expect(ldap.state, equals(ConnectionState.closed));
          expect(ldap.isAuthenticated, isFalse);

          // Trying to send a bind request on a closed connection fails.

          try {
            await ldap.bind();
            fail("Expected bind to fail");
          } catch (e) {
            expect(e, const TypeMatcher<StateError>());
          }

          expect(ldap.state, equals(ConnectionState.closed));
          expect(ldap.isAuthenticated, isFalse);

          // Trying to perform an LDAP operation on a closed connection fails.

          try {
            await doLdapOperation(ldap);
            // todo: this fails on dj because the search is not allowed
            //expect(false, isTrue);
          } catch (e) {
            expect(e, const TypeMatcher<StateError>());
          }

          expect(ldap.state, equals(ConnectionState.closed));
          expect(ldap.isAuthenticated, isFalse);
        });

        //----------------

        test("close test", () async {
          var ldap = new LdapConnection(
              host: p["host"], ssl: p["ssl"], port: p["port"]);
          await ldap.setAutomaticMode(false);

          expect(ldap.state, equals(ConnectionState.closed));
          expect(ldap.isAuthenticated, isFalse);
          expect(ldap.isAutomatic, isFalse);

          await ldap.open();

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

        test("using LDAPS", () async {
          var ldaps = new LdapConnection(
              host: s["host"],
              ssl: s["ssl"],
              port: s["port"],
              badCertificateHandler: (X509Certificate _) => true);
          // Note: setting badCertificateHandler to accept test certificate
          await ldaps.setAutomaticMode(false);

          expect(ldaps.state, equals(ConnectionState.closed));
          expect(ldaps.isAuthenticated, isFalse);
          expect(ldaps.isAutomatic, isFalse);

          // Open anonymous connection

          await ldaps.open();

          expect(ldaps.state, equals(ConnectionState.ready));
          expect(ldaps.isAuthenticated, isFalse);

          // LDAP operations can be performed on an open connection

          await doLdapOperation(ldaps);

          // Close connection

          await ldaps.close();

          expect(ldaps.state, equals(ConnectionState.closed));
          expect(ldaps.isAuthenticated, isFalse);
        });
      });

      group("authenticated", () {
        test("using LDAP", () async {
          var ldap = new LdapConnection(
              host: p["host"],
              ssl: p["ssl"],
              port: p["port"],
              bindDN: p["bindDN"],
              password: p["password"]);
          await ldap.setAutomaticMode(false);

          expect(ldap.isAuthenticated, isTrue);
          expect(ldap.state, equals(ConnectionState.closed));
          expect(ldap.isAutomatic, isFalse);

          // Normal expected sequence

          await ldap.open();

          expect(ldap.state, equals(ConnectionState.bindRequired));

          await ldap.bind();

          expect(ldap.state, equals(ConnectionState.ready));

          await doLdapOperation(ldap);

          await ldap.close();

          expect(ldap.state, equals(ConnectionState.closed));

          // Trying to perform an LDAP operation on a closed connection in
          // manual mode fails.

          try {
            await doLdapOperation(ldap);
            // todo: fixme
            //expect(false, isTrue);
          } catch (e) {
            expect(e, const TypeMatcher<StateError>());
          }

          expect(ldap.state, equals(ConnectionState.closed));

          // Trying to perform an LDAP operation on a connection that is
          // "opened but BIND not yet sent" for an authenticated connection
          // in manual mode fails.

          await ldap.open();

          expect(ldap.state, equals(ConnectionState.bindRequired));

          try {
            await doLdapOperation(ldap);
            // todo: fix me
            // expect(false, isTrue);
          } catch (e) {
            expect(e, const TypeMatcher<StateError>());
          }

          expect(ldap.state, equals(ConnectionState.bindRequired));

          // But after sending the necessary bind request, it works

          await ldap.bind();

          expect(ldap.state, equals(ConnectionState.ready));

          await doLdapOperation(ldap);

          await ldap.close();

          expect(ldap.state, equals(ConnectionState.closed));

          expect(ldap.isAuthenticated, isTrue);
        });

        //----------------

        test("using LDAPS", () async {
          var ldaps = new LdapConnection(
              host: s["host"],
              ssl: s["ssl"],
              port: s["port"],
              bindDN: p["bindDN"],
              password: p["password"],
              badCertificateHandler: (X509Certificate _) => true);
          // Note: setting badCertificateHandler to accept test certificate
          await ldaps.setAutomaticMode(false);

          expect(ldaps.isAuthenticated, isTrue);
          expect(ldaps.state, equals(ConnectionState.closed));
          expect(ldaps.isAutomatic, isFalse);

          await ldaps.open();

          expect(ldaps.isAuthenticated, isTrue);
          expect(ldaps.state, equals(ConnectionState.bindRequired));

          await ldaps.bind();

          expect(ldaps.isAuthenticated, isTrue);
          expect(ldaps.state, equals(ConnectionState.ready));

          await ldaps.close();

          expect(ldaps.isAuthenticated, isTrue);
          expect(ldaps.state, equals(ConnectionState.closed));

          // Test reopening a closed connection and closing in bindRequired state

          await ldaps.open();

          expect(ldaps.isAuthenticated, isTrue);
          expect(ldaps.state, equals(ConnectionState.bindRequired));

          await ldaps.close();

          expect(ldaps.isAuthenticated, isTrue);
          expect(ldaps.state, equals(ConnectionState.closed));
        });
      });
    });

    //----------------------------------------------------------------
    // Connecting incorrectly: mixing up LDAP and LDAPS

    group("mismatched protocol fails", () {
      //----------------

      test("using LDAPS on LDAP", () async {
        var bad =
            new LdapConnection(host: p["host"], ssl: true, port: p["port"]);
        await bad.setAutomaticMode(false);

        expect(bad.state, equals(ConnectionState.closed));

        try {
          await bad.open();
          expect(false, isTrue);
        } catch (e) {
          expect(e, const TypeMatcher<HandshakeException>());
        }

        // Connection cannot be established because handshake fails

        expect(bad.state, equals(ConnectionState.closed));
      });

      //----------------
      /*
    // Test does not work yet: can't capture the timeout exception

    test("using LDAP on LDAPS", () async {
      var bad = new LDAPConnection(s["host"],
          ssl: false, port: s["port"], autoConnect: false);

      expect(bad.state, equals(LdapConnectionState.closed));

      await bad.open();

      // try {
      //   await bad.connect();
      //   expect(false, isTrue);
      // } catch (e) {
      //   expect(e, const TypeMatcher<TimeoutException>());
      // }

      await bad.bind(); // TODO: should fail, but can't catch test's TimeoutException

      // Should not get to here
      assert(false);
      expect(bad.state, equals(LdapConnectionState.closed));
    }, timeout: new Timeout(new Duration(seconds: 3))
        // , skip: "this never fails and the test timesout"
        );
    */

      //----------------
    });

    //----------------------------------------------------------------

    group("TCP/IP socket fails", () {
      test("using LDAP on non-existant host", () async {
        var bad =
            new LdapConnection(host: badHost, ssl: p["ssl"], port: p["port"]);

        try {
          await bad.open();
          expect(false, isTrue);
        } catch (e) {
          expect(e, const TypeMatcher<LdapSocketRefusedException>());
          // expect(e, const TypeMatcher<LdapSocketServerNotFoundException>());

          expect(e, hasProperty("remoteServer", badHost));
        }
      });

      test("using LDAPS on non-existant host", () async {
        var bad =
            new LdapConnection(host: badHost, ssl: s["ssl"], port: s["port"]);

        try {
          await bad.open();
          expect(false, isTrue);
        } catch (e) {
          //expect(e, const TypeMatcher<LdapSocketServerNotFoundException>());
          expect(e, const TypeMatcher<LdapSocketRefusedException>());
          expect(e, hasProperty("remoteServer", badHost));
        }
      });

      test("using LDAP on non-existant port", () async {
        var bad =
            new LdapConnection(host: p["host"], ssl: p["ssl"], port: badPort);

        try {
          await bad.open();
          expect(false, isTrue);
        } catch (e) {
          expect(e, const TypeMatcher<LdapSocketRefusedException>());
          expect(e, hasProperty("remoteServer", p["host"]));
          expect(e, hasProperty("remotePort", badPort));
          expect(e, hasProperty("localPort"));
        }
      });

      test("using LDAPS on non-existant port", () async {
        var bad =
            new LdapConnection(host: s["host"], ssl: s["ssl"], port: badPort);

        try {
          await bad.open();
          expect(false, isTrue);
        } catch (e) {
          expect(e, const TypeMatcher<LdapSocketRefusedException>());
          expect(e, hasProperty("remoteServer", s["host"]));
          expect(e, hasProperty("remotePort", badPort));
          expect(e, hasProperty("localPort"));
        }
      });
    });

    //----------------------------------------------------------------

    group('LDAP bind', () {
      //----------------

      test('with constructor credentials', () async {
        var ldap = new LdapConnection(
            host: p["host"],
            ssl: p["ssl"],
            port: p["port"],
            bindDN: p["bindDN"],
            password: p["password"]);
        await ldap.setAutomaticMode(false);

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));

        // Open connection

        await ldap.open();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.bindRequired));

        // Bind

        var result = await ldap.bind();
        expect(result, const TypeMatcher<LdapResult>());
        expect(result.resultCode, equals(ResultCode.OK));

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));

        // Change from authenticated to anonymous

        await ldap.setAnonymous();

        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.state, equals(ConnectionState.bindRequired));

        // Bind to apply change

        result = await ldap.bind();
        expect(result, const TypeMatcher<LdapResult>());
        expect(result.resultCode, equals(ResultCode.OK));

        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.state, equals(ConnectionState.ready));

        // Change from anonymous to authenticated

        await ldap.setAuthentication(p["bindDN"], p["password"]);

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.bindRequired));

        // Bind to apply change

        result = await ldap.bind();
        expect(result, const TypeMatcher<LdapResult>());
        expect(result.resultCode, equals(ResultCode.OK));

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));

        // Close

        await ldap.close();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));
      });

      //----------------

      test('with setAuthentication credentials', () async {
        var ldap =
            new LdapConnection(host: p["host"], ssl: p["ssl"], port: p["port"]);
        await ldap.setAutomaticMode(false);

        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.state, equals(ConnectionState.closed));

        // Set authentication

        await ldap.setAuthentication(p["bindDN"], p["password"]);

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));

        // Open

        await ldap.open();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.bindRequired));

        // Bind

        var result = await ldap.bind();
        expect(result, const TypeMatcher<LdapResult>());
        expect(result.resultCode, equals(ResultCode.OK));

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));
      });

      //----------------

      test('with bad DN fails', () async {
        var ldap =
            new LdapConnection(host: p["host"], ssl: p["ssl"], port: p["port"]);
        await ldap.setAutomaticMode(false);

        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.state, equals(ConnectionState.closed));

        await ldap.open();

        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.state, equals(ConnectionState.ready));

        // Set invalid credentials

        await ldap.setAuthentication(
            "cn=unknown,dc=example,dc=com", p["password"]);

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.bindRequired));

        // Bind

        try {
          await ldap.bind();
          expect(false, isTrue);
        } catch (e) {
          expect(e, const TypeMatcher<LdapResultInvalidCredentialsException>());
        }
      });

      //----------------

      test('with bad password fails', () async {
        var ldap =
            new LdapConnection(host: p["host"], ssl: p["ssl"], port: p["port"]);
        await ldap.setAutomaticMode(false);

        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.state, equals(ConnectionState.closed));

        await ldap.open();

        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.state, equals(ConnectionState.ready));

        // Set invalid credentials

        await ldap.setAuthentication(p["bindDN"], "INCORRECT_PASSWORD");

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.bindRequired));

        // Bind

        try {
          await ldap.bind();
          expect(false, isTrue);
        } catch (e) {
          expect(e, const TypeMatcher<LdapResultInvalidCredentialsException>());
        }
      });
    }); // end group
  }); // end "manual mode" group

  //================================================================

  group("Automatic mode", () {
    //----------------------------------------------------------------
    // Binding correctly

    group("automatic open", () {
      test("anonymous", () async {
        var ldap =
            new LdapConnection(host: p["host"], ssl: p["ssl"], port: p["port"]);

        expect(ldap.state, equals(ConnectionState.closed));
        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.isAutomatic, isTrue);

        // Perform an LDAP operation to automatically open the connection.
        // Since this is an anonymous connection, no BIND request is sent.

        await doLdapOperation(ldap);

        expect(ldap.state, equals(ConnectionState.ready));
        expect(ldap.isAuthenticated, isFalse);

        // Connections can be closed, even in automatic mode.

        await ldap.close();

        expect(ldap.state, equals(ConnectionState.closed));
        expect(ldap.isAuthenticated, isFalse);

        // Explicitly open the connection. This operation is unnecessary in
        // automatic mode, but it might be useful to test whether the
        // host and port are correct.

        await ldap.open();

        expect(ldap.state, equals(ConnectionState.ready));
        expect(ldap.isAuthenticated, isFalse);

        // Close

        await ldap.close();

        expect(ldap.state, equals(ConnectionState.closed));
        expect(ldap.isAuthenticated, isFalse);

        // Explicitly send a bind request. Since this is an anonymous
        // connection, the bind will be to an empty DN with an empty password,
        // but it will cause the connection to be opened.

        await ldap.bind();

        expect(ldap.state, equals(ConnectionState.ready));
        expect(ldap.isAuthenticated, isFalse);

        // Redundant open. In automatic mode (unlike in manual mode),
        // opening an already open connection does not raise an exception.

        await ldap.open();

        expect(ldap.state, equals(ConnectionState.ready));
        expect(ldap.isAuthenticated, isFalse);
      });

      test("authenticated", () async {
        var ldap = new LdapConnection(
            host: p["host"],
            ssl: p["ssl"],
            port: p["port"],
            bindDN: p["bindDN"],
            password: p["password"]);

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));
        expect(ldap.isAutomatic, isTrue);

        // Perform an LDAP operation: should automaticall open and bind
        // the connection.

        await doLdapOperation(ldap);

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));

        // Automatic connections can be closed

        await ldap.close();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));

        // Automatic connections can be explicitly opened, but it will also
        // automatically bind authenticated connections.

        await ldap.open();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));

        // Close it again

        await ldap.close();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));

        // On a closed connection, asking for a bind request will
        // automatically open the connection and then send the bind request.

        await ldap.bind();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));
      });
    });

    //----------------------------------------------------------------

    group('automatic bind', () {
      //----------------

      test('succeess', () async {
        var ldap = new LdapConnection(
            host: p["host"],
            ssl: p["ssl"],
            port: p["port"],
            bindDN: p["bindDN"],
            password: p["password"]);
        await ldap.setAutomaticMode(true);

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));

        // Open connection

        await ldap.open();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));

        // Change from authenticated to anonymous

        await ldap.setAnonymous();

        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.state, equals(ConnectionState.ready));

        // Change from anonymous to authenticated

        await ldap.setAuthentication(p["bindDN"], p["password"]);

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));

        // Close

        await ldap.close();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));
      });

      //----------------

      test('with bad password fails with LDAP operation', () async {
        var ldap = new LdapConnection(
            host: p["host"],
            ssl: p["ssl"],
            port: p["port"],
            bindDN: p["bindDN"],
            password: "INCORRECT_PASSWORD");

        expect(ldap.isAutomatic, isTrue);
        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));

        try {
          await doLdapOperation(ldap);
          fail("LDAP operation succeeded when it should have failed");
        } catch (e) {
          expect(e, const TypeMatcher<LdapResultInvalidCredentialsException>());
        }

        await ldap.close();
      });

      //----------------

      test('with bad password fails with explicit open', () async {
        var ldap = new LdapConnection(
            host: p["host"],
            ssl: p["ssl"],
            port: p["port"],
            bindDN: p["bindDN"],
            password: "INCORRECT_PASSWORD");

        expect(ldap.isAutomatic, isTrue);
        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));

        try {
          await ldap.open();
          fail("open succeeded when it should not have");
        } catch (e) {
          expect(e, const TypeMatcher<LdapResultInvalidCredentialsException>());
        }

        await ldap.close();
      });

      //----------------

      test('with bad password fails with setAuthentication', () async {
        var ldap =
            new LdapConnection(host: p["host"], ssl: p["ssl"], port: p["port"]);

        expect(ldap.isAutomatic, isTrue);
        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.state, equals(ConnectionState.closed));

        await ldap.open();

        expect(ldap.state, equals(ConnectionState.ready));

        try {
          // Setting the credentials on an opened connection will automatically
          // send a BIND request.

          await ldap.setAuthentication(p["bindDN"], "INCORRECT_PASSWORD");
          fail("setAuthentication succeeded when it should not have");
        } catch (e) {
          expect(e, const TypeMatcher<LdapResultInvalidCredentialsException>());
        }
        await ldap.close();
      });
    }); // end group

    //----------------------------------------------------------------

    group('explicit invocation still allowed', () {
      //----------------

      test('for open', () async {
        var ldap = new LdapConnection(
            host: p["host"],
            ssl: p["ssl"],
            port: p["port"],
            bindDN: p["bindDN"],
            password: p["password"]);

        expect(ldap.isAutomatic, isTrue);
        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));

        // Redundant open

        await ldap.open();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));

        // Another redundant open

        await ldap.open();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));

        // Close

        await ldap.close();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));
      });

      //----------------

      test('for bind', () async {
        var ldap = new LdapConnection(
            host: p["host"],
            ssl: p["ssl"],
            port: p["port"],
            bindDN: p["bindDN"],
            password: p["password"]);

        expect(ldap.isAutomatic, isTrue);
        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));

        // Bind

        var result = await ldap.bind();
        expect(result, const TypeMatcher<LdapResult>());
        expect(result.resultCode, equals(ResultCode.OK));

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));

        // Change from authenticated to anonymous

        await ldap.setAnonymous();

        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.state, equals(ConnectionState.ready));

        // Redundant bind

        result = await ldap.bind();
        expect(result, const TypeMatcher<LdapResult>());
        expect(result.resultCode, equals(ResultCode.OK));

        expect(ldap.isAuthenticated, isFalse);
        expect(ldap.state, equals(ConnectionState.ready));

        // Change from anonymous to authenticated

        await ldap.setAuthentication(p["bindDN"], p["password"]);

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));

        // Redundant bind

        result = await ldap.bind();
        expect(result, const TypeMatcher<LdapResult>());
        expect(result.resultCode, equals(ResultCode.OK));

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.ready));

        // Close

        await ldap.close();

        expect(ldap.isAuthenticated, isTrue);
        expect(ldap.state, equals(ConnectionState.closed));
      }); // end "for bind" group
    }); // end "explicit invocation still allowed" group
  }); // end "automatic mode" group
}
