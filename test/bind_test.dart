// Tests connection and binding.
//
//----------------------------------------------------------------

import 'dart:io';
import 'package:test/test.dart';
import 'package:matcher/mirror_matchers.dart';
import 'package:dart_config/default_server.dart' as config_file;

import 'package:dartdap/dartdap.dart';

//----------------------------------------------------------------

const String testConfigFile = "test/TEST-config.yaml";

var badHost = "doesNotExist.example.com";
var badPort = 10999; // there must not be anything listing on this port

//----------------------------------------------------------------

main() async {
  // Create two connections from parameters in the config file

  var p = (await config_file.loadConfig(testConfigFile))["test-LDAP"];
  assert(p["ssl"] == null || p["ssl"] == false);

  var s = (await config_file.loadConfig(testConfigFile))["test-LDAPS"];
  assert(s["ssl"] == true);

  //  startQuickLogging();

  //----------------------------------------------------------------
  // Binding correctly

  group("Connect succeeds", () {
    test("using LDAP", () async {
      var plain = new LDAPConnection(
          p["host"], p["port"], p["ssl"], p["bindDN"], p["password"]);

      expect(plain.isClosed(), isTrue);
      await plain.connect();
      expect(plain.isClosed(), isFalse);
      plain.close();
    });

    //----------------

    test("using LDAPS", () async {
      var secured = new LDAPConnection(
          s["host"], s["port"], s["ssl"], s["bindDN"], s["password"]);

      expect(secured.isClosed(), isTrue);
      await secured.connect();
      expect(secured.isClosed(), isFalse);
      secured.close();
    });
  });

  //----------------------------------------------------------------
  // Binding incorrectly: mixing up LDAP and LDAPS

  group("Connect protocol fails", () {
    //----------------

    test("using LDAPS on LDAP", () async {
      var bad = new LDAPConnection(
          p["host"], p["port"], true, p["bindDN"], p["password"]);

      expect(bad.connect(), throwsA(new isInstanceOf<HandshakeException>()));
      // Connection terminated during handshake
      expect(bad.isClosed(), isTrue);
    });

    //----------------

    /*
    // Test does not work yet: can't capture the timeout exception

    test("using LDAP on LDAPS", () async {
      var bad = new LDAPConnection(
          s["host"], s["port"], false, s["bindDN"], s["password"]);

      expect(bad.connect(),
          throwsA(new isInstanceOf<TimeoutException>())); // TODO: fix
      expect(bad.isClosed(), isTrue);
    },
        timeout: new Timeout(new Duration(seconds: 10)),
        skip: "this never fails and the test timesout");
        */
  });

  //----------------------------------------------------------------

  group("Connect TCP fails", () {
    test("using LDAP on non-existant host", () async {
      var bad = new LDAPConnection(
          badHost, p["port"], p["ssl"], p["bindDN"], p["password"]);

      expect(
          bad.connect(),
          throwsA(allOf(new isInstanceOf<LdapSocketServerNotFoundException>(),
              hasProperty("remoteServer", badHost))));
    });

    test("using LDAPS on non-existant host", () async {
      var bad = new LDAPConnection(
          badHost, s["port"], s["ssl"], s["bindDN"], s["password"]);

      expect(
          bad.connect(),
          throwsA(allOf(new isInstanceOf<LdapSocketServerNotFoundException>(),
              hasProperty("remoteServer", badHost))));
    });

    test("using LDAP on non-existant port", () async {
      var bad = new LDAPConnection(
          p["host"], badPort, p["ssl"], p["bindDN"], p["password"]);

      expect(
          bad.connect(),
          throwsA(allOf(
              new isInstanceOf<LdapSocketRefusedException>(),
              hasProperty("remoteServer", p["host"]),
              hasProperty("remotePort", badPort),
              hasProperty("localPort"))));
    });

    test("using LDAPS on non-existant port", () async {
      var bad = new LDAPConnection(
          s["host"], badPort, s["ssl"], s["bindDN"], s["password"]);

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
      ldap = new LDAPConnection(
          p["host"], p["port"], p["ssl"], p["bindDN"], p["password"]);

      expect(ldap.isClosed(), isTrue);
      await ldap.connect();
      expect(ldap.isClosed(), isFalse);
    });

    tearDown(() {
      return ldap.close();
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
