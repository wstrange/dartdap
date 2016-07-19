// Tests connection and binding.
//
//----------------------------------------------------------------

import 'dart:io';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:matcher/mirror_matchers.dart';
import 'package:dart_config/default_server.dart' as config_file;

import 'package:dartdap/dartdap.dart';

//----------------------------------------------------------------

const String testConfigFile = "test/TEST-config.yaml";

var badHost = "doesNotExist.example.com";
var badPort = 10999; // there must not be anything listing on this port

// Enable logging by setting to true.
//
// This will probably print out these log entries:
//
// ...: ldap.connection: WARNING: Invalid Certificate: issuer=localhost subject=localhost
// ...: ldap.connection: WARNING: SSL Connection will proceed. Please fix the certificate
// ...: ldap.recv.bytes: INFO: Connection closed gracefully with no leftover bytes to parse

const bool doLogging = false;

//----------------------------------------------------------------

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

    var commonLevel = Level.INFO;

    new Logger("ldap").level = commonLevel;
    new Logger("ldap.connection").level = Level.INFO;
    new Logger("ldap.recv.bytes").level = Level.INFO;
  }

  //----------------------------------------------------------------
  // Binding correctly

  group("Connect succeeds", () {
    test("using LDAP", () async {
      var plain = new LDAPConnection(p["host"], p["port"], p["ssl"]);

      expect(plain.isClosed(), isTrue);
      await plain.connect();
      expect(plain.isClosed(), isFalse);
      await plain.close();
    });

    //----------------

    test("using LDAPS", () async {
      var secured =
          new LDAPConnection(s["host"], s["port"], s["ssl"]);

      expect(secured.isClosed(), isTrue);
      await secured.connect();
      expect(secured.isClosed(), isFalse);
      await secured.close();

      // Delay so any logging can get printed before the next test is run.
      var c = new Completer();
      new Timer(new Duration(seconds: 1), () {
        c.complete();
      });
      await c.future;
    });
  });

  //----------------------------------------------------------------
  // Binding incorrectly: mixing up LDAP and LDAPS

  group("Connect protocol fails", () {
    //----------------

    test("using LDAPS on LDAP", () async {
      var bad = new LDAPConnection(p["host"], p["port"], true);

      expect(bad.connect(), throwsA(new isInstanceOf<HandshakeException>()));
      // Connection terminated during handshake
      expect(bad.isClosed(), isTrue);
    });

    //----------------
    /*
    // Test does not work yet: can't capture the timeout exception

    test("using LDAP on LDAPS", () async {
      var bad = new LDAPConnection(s["host"], ssl: false, port: s["port"]);

      await bad.connect();

      // expect(bad.connect(),
      //   throwsA(new isInstanceOf<TimeoutException>()));

      var result = await bad.bind(p["bindDN"], p["password"]);
      expect(result, new isInstanceOf<LDAPResult>());
      expect(result.resultCode, equals(ResultCode.OK));

      expect(bad.isClosed(), isTrue);

    },
        timeout: new Timeout(new Duration(seconds: 3))
      // , skip: "this never fails and the test timesout"
    );
    */
  });

  //----------------------------------------------------------------

  group("Connect TCP fails", () {
    test("using LDAP on non-existant host", () async {
      var bad = new LDAPConnection(badHost,  p["port"], p["ssl"]);

      expect(
          bad.connect(),
          throwsA(allOf(new isInstanceOf<LdapSocketServerNotFoundException>(),
              hasProperty("remoteServer", badHost))));
    });

    test("using LDAPS on non-existant host", () async {
      var bad = new LDAPConnection(badHost, s["port"], s["ssl"]);

      expect(
          bad.connect(),
          throwsA(allOf(new isInstanceOf<LdapSocketServerNotFoundException>(),
              hasProperty("remoteServer", badHost))));
    });

    test("using LDAP on non-existant port", () async {
      var bad = new LDAPConnection(p["host"], badPort, p["ssl"]);

      expect(
          bad.connect(),
          throwsA(allOf(
              new isInstanceOf<LdapSocketRefusedException>(),
              hasProperty("remoteServer", p["host"]),
              hasProperty("remotePort", badPort),
              hasProperty("localPort"))));
    });

    test("using LDAPS on non-existant port", () async {
      var bad = new LDAPConnection(s["host"], badPort, s["ssl"]);

      expect(
          bad.connect(),
          throwsA(allOf(
              new isInstanceOf<LdapSocketRefusedException>(),
              hasProperty("remoteServer", s["host"]),
              hasProperty("remotePort", badPort),
              hasProperty("localPort"))));
    });
  });

  //----------------------------------------------------------------

  group('LDAP bind', () {
    var ldap;

    setUp(() async {
      ldap = new LDAPConnection(p["host"], p["port"], p["ssl"]);

      expect(ldap.isClosed(), isTrue);
      await ldap.connect();
      expect(ldap.isClosed(), isFalse);
    });

    tearDown(() async {
      await ldap.close();
    });

    test('with default credentials', () async {
      var result = await ldap.bind();
      expect(result, new isInstanceOf<LDAPResult>());
      expect(result.resultCode, equals(ResultCode.OK));
    });

    test('with explicit credentials', () async {
      var result = await ldap.bind(p["bindDN"], p["password"]);
      expect(result, new isInstanceOf<LDAPResult>());
      expect(result.resultCode, equals(ResultCode.OK));
    });

    test('with bad DN fails', () async {
      expect(
          ldap.bind("cn=unknown,dc=example,dc=com", p["password"]),
          throwsA(allOf(
              new isInstanceOf<LdapResultInvalidCredentialsException>())));
    });

    test('with incorrect password fails', () async {
      expect(
          ldap.bind(p["bindDN"], "thisIsNotThePassword"),
          throwsA(allOf(
              new isInstanceOf<LdapResultInvalidCredentialsException>())));
    });
  }); // end group
}
