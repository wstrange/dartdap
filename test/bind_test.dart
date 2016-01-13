// Tests connection and binding.
//
//----------------------------------------------------------------

import 'dart:io';
import 'package:test/test.dart';
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
    });

    //----------------

    /*
    test("using LDAP on LDAPS", () async {

      var config = new LDAPConfiguration(secured.host,
          ssl: false, // LDAP
          port: secured.port,
          bindDN: secured.bindDN,
          password: secured.password);
      var ldap = await config.getConnection();

      expect(
          config.getConnection(),
          throwsA(new isInstanceOf<HandshakeException>())
             );

      ldap.close();
    },
        timeout: new Timeout(new Duration(minutes: 10))
        , skip: "this never fails and the test timesout"
      );
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
          config.getConnection(), throwsA(new isInstanceOf<SocketException>()));

      // errno=8; nodename nor servname provided
    });

    test("using LDAPS on non-existant host", () async {
      var config = new LDAPConfiguration(badHost, // host does not exist
          ssl: secured.ssl,
          port: secured.port,
          bindDN: secured.bindDN,
          password: secured.password);
      expect(
          config.getConnection(), throwsA(new isInstanceOf<SocketException>()));
    });

    test("using LDAP on non-existant port", () async {
      var config = new LDAPConfiguration(plain.host,
          ssl: plain.ssl,
          port: badPort, // port does not exist
          bindDN: plain.bindDN,
          password: plain.password);

      expect(
          config.getConnection(), throwsA(new isInstanceOf<SocketException>()));
      // errno = 61 connection refused
    });

    test("using LDAPS on non-existant port", () async {
      var config = new LDAPConfiguration(secured.host,
          ssl: secured.ssl,
          port: badPort, // port does not exist
          bindDN: secured.bindDN,
          password: secured.password);

      expect(
          config.getConnection(), throwsA(new isInstanceOf<SocketException>()));
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
      expect(result.resultCode, equals(0));
    });

    test('with explicit credentials', () async {
      return ldap.bind(plain.bindDN, plain.password).then((c) {
        // print("got result $c ${c.runtimeType}");
      });
    });

    test('with explicit credentials using async', () async {
      try {
        var r = await ldap.bind(plain.bindDN, plain.password);
        expect(r.resultCode, equals(0));
      } catch (e) {
        fail("unexpected exception $e");
      }
    });

    test('with bad DN fails', () async {
      try {
        await ldap.bind("cn=unknown,dc=example,dc=com", plain.password);
        fail("Should not be able to bind to a bad DN");
      } catch (e) {
        expect(e.resultCode, equals(ResultCode.INVALID_CREDENTIALS));
      }
    });

    test('with incorrect password fails', () async {
      try {
        await ldap.bind(plain.bindDN, "thisIsNotThePassword");
        fail("Should not be able to bind with an incorrect password");
      } catch (e) {
        expect(e.resultCode, equals(ResultCode.INVALID_CREDENTIALS));
      }
    });
  }); // end group
}
