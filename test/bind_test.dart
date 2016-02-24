// Tests connection and binding.
//
//----------------------------------------------------------------

import 'dart:io';
import 'package:test/test.dart';
import 'package:matcher/mirror_matchers.dart';

import 'package:dartdap/dartdap.dart';

//----------------------------------------------------------------

const String testConfigFile = "test/TEST-config.yaml";

var badHost = "doesNotExist.example.com";
var badPort = 10999; // there must not be anything listing on this port

//----------------------------------------------------------------

main() {
  LDAPConnection ldap;
  var plain = new LDAPConfiguration.fromFile(testConfigFile, "test-LDAP");
  var secured = new LDAPConfiguration.fromFile(testConfigFile, "test-LDAPS");

  //  startQuickLogging();

  //----------------------------------------------------------------
  // Binding correctly

  group("Connect succeeds", () {
    test("using LDAP", () async {
      var ldap = await plain.getConnection();

      expect(plain.ssl, isFalse);
      expect(ldap, isNotNull);

      ldap.close();
    });

    //----------------

    test("using LDAPS", () async {
      var ldap = await secured.getConnection();

      expect(secured.ssl, isTrue);
      expect(ldap, isNotNull);

      ldap.close();
    });
  });

  //----------------------------------------------------------------
  // Binding incorrectly: mixing up LDAP and LDAPS

  group("Connect protocol fails", () {
    //----------------

    test("using LDAPS on LDAP", () async {
      var config = new LDAPConfiguration(plain.host,
          ssl: true, // LDAP
          port: plain.port,
          bindDN: plain.bindDN,
          password: plain.password);

      expect(config.getConnection(),
          throwsA(new isInstanceOf<HandshakeException>()));
      // Connection terminated during handshake
    });

    //----------------

    /*
    // Test does not work yet: can't capture the timeout exception

    test("using LDAP on LDAPS", () async {
      var config = new LDAPConfiguration(secured.host,
          ssl: false, // LDAP
          port: secured.port,
          bindDN: secured.bindDN,
          password: secured.password);
      var ldap = await config.getConnection();

      expect(config.getConnection(),
          throwsA(new isInstanceOf<TimeoutException>())); // TODO: fix

      ldap.close();
    },
        timeout: new Timeout(new Duration(seconds: 10)),
        skip: "this never fails and the test timesout");
        */
  });

  //----------------------------------------------------------------

  group("Connect TCP fails", () {
    test("using LDAP on non-existant host", () async {
      var config = new LDAPConfiguration(badHost, // host does not exist
          ssl: plain.ssl,
          port: plain.port,
          bindDN: plain.bindDN,
          password: plain.password);

      expect(
          config.getConnection(),
          throwsA(allOf(new isInstanceOf<LdapSocketServerNotFoundException>(),
              hasProperty("remoteServer", badHost))));
    });

    test("using LDAPS on non-existant host", () async {
      var config = new LDAPConfiguration(badHost, // host does not exist
          ssl: secured.ssl,
          port: secured.port,
          bindDN: secured.bindDN,
          password: secured.password);

      expect(
          config.getConnection(),
          throwsA(allOf(new isInstanceOf<LdapSocketServerNotFoundException>(),
              hasProperty("remoteServer", badHost))));
    });

    test("using LDAP on non-existant port", () async {
      var config = new LDAPConfiguration(plain.host,
          ssl: plain.ssl,
          port: badPort, // port does not exist
          bindDN: plain.bindDN,
          password: plain.password);

      expect(
          config.getConnection(),
          throwsA(allOf(
              new isInstanceOf<LdapSocketRefusedException>(),
              hasProperty("remoteServer", plain.host),
              hasProperty("remotePort", badPort),
              hasProperty("localPort"))));
    });

    test("using LDAPS on non-existant port", () async {
      var config = new LDAPConfiguration(secured.host,
          ssl: secured.ssl,
          port: badPort, // port does not exist
          bindDN: secured.bindDN,
          password: secured.password);

      expect(
          config.getConnection(),
          throwsA(allOf(
              new isInstanceOf<LdapSocketRefusedException>(),
              hasProperty("remoteServer", secured.host),
              hasProperty("remotePort", badPort),
              hasProperty("localPort"))));
    });
  });

  //----------------------------------------------------------------

  group('LDAP bind', () {
    setUp(() async {
      ldap = await plain.getConnection(false);
    });

    tearDown(() {
      return plain.close();
    });

    test('with default credentials', () async {
      var result = await ldap.bind();
      expect(result, new isInstanceOf<LDAPResult>());
      expect(result.resultCode, equals(ResultCode.OK));
    });

    test('with explicit credentials', () async {
      var result = await ldap.bind(plain.bindDN, plain.password);
      expect(result, new isInstanceOf<LDAPResult>());
      expect(result.resultCode, equals(ResultCode.OK));
    });

    test('with bad DN fails', () async {
      expect(ldap.bind("cn=unknown,dc=example,dc=com", plain.password),
          throwsA(allOf(new isInstanceOf<LdapResultInvalidCredentialsException>())));
    });

    test('with incorrect password fails', () async {
      expect(ldap.bind(plain.bindDN, "thisIsNotThePassword"),
          throwsA(allOf(new isInstanceOf<LdapResultInvalidCredentialsException>())));
    });
  }); // end group
}
