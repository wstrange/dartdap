// Tests connection open, close and bind.
//
//----------------------------------------------------------------

import 'dart:io';
import 'dart:async';

import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';

import 'util.dart' as util;

//----------------------------------------------------------------

var badHost = 'doesNotExist.example.com';
var badPort = 10999; // there must not be anything listing on this port

/// Not all ldap servers allow anonymous search
///
/// If the LDAP directory used for testing does not allow anonymous searches,
/// set this to false and the tests that perform an anonymous search will be
/// skipped. Set it to true to include those tests.

var allowAnonymousSearch = true;

//----------------------------------------------------------------

/// Perform some LDAP operation.
///
/// For the purpose of the tests in this file, this can be any operation
/// (except for BIND) which will require the connection to be open.
///
FutureOr<void> doLdapOperation(LdapConnection ldap, DN testDN) async {
  var filter = Filter.present('cn');
  var searchAttrs = ['cn', 'sn'];

  // This search actually should not find any results, but that doesn't matter

  var searchResults =
      await ldap.search(testDN.dn, filter, searchAttrs, sizeLimit: 100);
  var ldapResult = await searchResults.getLdapResult();
  print('bound = ${ldap.isBound}  ssl= ${ldap.isSSL} $ldapResult');
  await for (SearchEntry entry in searchResults.stream) {
    expect(entry, isNotNull);
    expect(entry, const TypeMatcher<SearchEntry>());
    print('got entry ${entry.dn}');
  }
}

Future<void> _doBind(LdapConnection ldap, DN testDN) async {
  expect(ldap.state, equals(ConnectionState.closed));
  expect(ldap.isBound, isFalse);
  await ldap.open();

  expect(ldap.state, equals(ConnectionState.ready));
  expect(ldap.isBound, isFalse);

  await doLdapOperation(ldap, testDN);

  // Close the connection

  await ldap.close();

  expect(ldap.state, equals(ConnectionState.closed));
  expect(ldap.isBound, isFalse);

  // Open it again

  await ldap.open();

  expect(ldap.state, equals(ConnectionState.ready));
  expect(ldap.isBound, isFalse);

  // Redundant open. Opening
  // an already open connection raises an exception. The invoker is
  // expected to track whether their connection is open or not.

  try {
    await ldap.open();
    expect(false, isTrue);
  } catch (e) {
    expect(e, const TypeMatcher<StateError>());
  }

  expect(ldap.state, equals(ConnectionState.ready));
  expect(ldap.isBound, isFalse);

  // Close it

  await ldap.close();

  expect(ldap.state, equals(ConnectionState.closed));
  expect(ldap.isBound, isFalse);

  // Closing an already closed connection is permitted, even though
  // it does nothing.

  await ldap.close();

  expect(ldap.state, equals(ConnectionState.closed));
  expect(ldap.isBound, isFalse);

  // Trying to send a bind request on a closed connection fails.

  try {
    await ldap.bind();
    fail('Expected bind to fail');
  } catch (e) {
    expect(e, const TypeMatcher<LdapUsageException>());
  }

  expect(ldap.state, equals(ConnectionState.closed));
  expect(ldap.isBound, isFalse);

  // Trying to perform an LDAP operation on a closed connection fails.

  try {
    await doLdapOperation(ldap, testDN);
    // todo: this fails on dj because the search is not allowed
    //expect(false, isTrue);
  } catch (e) {
    expect(e, const TypeMatcher<LdapUsageException>());
  }

  expect(ldap.state, equals(ConnectionState.closed));
  expect(ldap.isBound, isFalse);
}

//----------------------------------------------------------------

void main() async {
  final config = util.Config();

  // Get the configurations for the two types of connections

  final normal = config.directory(util.noLdapsDirectoryName);
  final secure = config.directory(util.ldapsDirectoryName);

  runTests(normal, secure);

  // TODO: Refactor bind tests to not require TLS.
  // This will assist automated testing using a GH action / openldap -
  // where TLS may not be easily configured.
  //
  // if (normal != null) {
  //   // The tests need both LDAP (without TLS) and LDAPS (with TLS) directories
  //   runTests(normal, secure);
  // } else {
  //   test('bind tests', () {}, skip: true); // to produce a skip message
  // }
}

void runTests(util.ConfigDirectory normal, util.ConfigDirectory secure) {
  assert(!normal.ssl,
      '${util.noLdapsDirectoryName} has TLS when it must be LDAP only');
  assert(secure.ssl,
      '${util.ldapsDirectoryName} without TLS when it must be LDAPS');

  //================================================================
  group('connect succeeds', () {
    group('anonymous', () {
      test('using LDAP', () async {
        var ldap = LdapConnection(
            host: normal.host, ssl: normal.ssl, port: normal.port);
        await ldap.open();
        // todo - what can we do with anonymous connections on all ldap servers
      });

      //----------------

      test('close test', () async {
        var ldap = LdapConnection(
            host: normal.host, ssl: normal.ssl, port: normal.port);

        expect(ldap.state, equals(ConnectionState.closed));
        expect(ldap.isBound, isFalse);

        await ldap.open();

        expect(ldap.state, equals(ConnectionState.ready));
        expect(ldap.isBound, isFalse);

        // LDAP operations can be performed on an open connection
        await doLdapOperation(ldap, normal.testDN);

        // Close the connection

        await ldap.close();

        expect(ldap.state, equals(ConnectionState.closed));
        expect(ldap.isBound, isFalse);
      });

      //----------------

      test('using LDAPS', () async {
        var ldaps = LdapConnection(
            host: secure.host,
            ssl: secure.ssl,
            port: secure.port,
            badCertificateHandler: (X509Certificate _) => true);
        // Note: setting badCertificateHandler to accept test certificate

        expect(ldaps.state, equals(ConnectionState.closed));
        expect(ldaps.isBound, isFalse);

        // Open anonymous connection

        await ldaps.open();

        expect(ldaps.state, equals(ConnectionState.ready));
        expect(ldaps.isBound, isFalse);

        // LDAP operations can be performed on an open connection

        await doLdapOperation(ldaps, normal.testDN);

        // Close connection

        await ldaps.close();

        expect(ldaps.state, equals(ConnectionState.closed));
        expect(ldaps.isBound, isFalse);
      });
    }, skip: !allowAnonymousSearch);

    group('authenticated', () {
      test('using LDAP', () async {
        var ldap = LdapConnection(
            host: normal.host,
            ssl: normal.ssl,
            port: normal.port,
            bindDN: normal.bindDN,
            password: normal.password);

        await _doBind(ldap, normal.testDN);
      });

      //----------------

      test('using LDAPS', () async {
        var ldaps = LdapConnection(
            host: secure.host,
            ssl: secure.ssl,
            port: secure.port,
            bindDN: normal.bindDN,
            password: normal.password,
            badCertificateHandler: (X509Certificate _) => true);
        // Note: setting badCertificateHandler to accept test certificate

        await _doBind(ldaps, secure.testDN);
      });
    });
  });

  //----------------------------------------------------------------
  // Connecting incorrectly: mixing up LDAP and LDAPS

  group('mismatched protocol fails', () {
    //----------------

    test('using LDAPS on LDAP', () async {
      var bad = LdapConnection(host: normal.host, ssl: true, port: normal.port);

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

    test('using LDAP on LDAPS', () async {
      var bad = LDAPConnection(secure.host,
          ssl: false, port: secure.port, autoConnect: false);

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
    }, timeout: Timeout(Duration(seconds: 3))
        // , skip: 'this never fails and the test timesout'
        );
    */

    //----------------
  });

  //----------------------------------------------------------------

  group('TCP/IP socket fails', () {
    test('using LDAP on non-existant host', () async {
      var bad =
          LdapConnection(host: badHost, ssl: normal.ssl, port: normal.port);

      try {
        await bad.open();
        fail('should not get here');
      } on LdapSocketServerNotFoundException catch (e) {
        // TODO: confirm behaviour and fix dartdap if necessary
        //
        // Previously, LdapSocketRefusedException was expected and
        // LdapSocketServerNotFoundException was commented out.
        //
        // LdapSocketServerNotFoundException is thrown when connecting
        // to an OpenLDAP server (from Dart 2.8.4 on macOS connecting to
        // OpenLDAP running on CentOS 7.2). Does it throw
        // LdapSocketRefusedException with a different setup?

        // expect(e, const TypeMatcher<LdapSocketRefusedException>());
        expect(e.remoteServer, equals(badHost));
      }
    });

    test('using LDAPS on non-existant host', () async {
      var bad =
          LdapConnection(host: badHost, ssl: secure.ssl, port: secure.port);

      try {
        await bad.open();
        expect(false, isTrue);
      } catch (e) {
        // TODO:  confirm behaviour and fix dartdap if necessary (see above)

        expect(e, const TypeMatcher<LdapSocketServerNotFoundException>());
        //expect(e, const TypeMatcher<LdapSocketRefusedException>());
        //expect(e, hasProperty('remoteServer', badHost));
      }
    });

    test('using LDAP on non-existant port', () async {
      var bad =
          LdapConnection(host: normal.host, ssl: normal.ssl, port: badPort);

      try {
        await bad.open();
        expect(false, isTrue);
      } on LdapSocketRefusedException catch (e) {
        expect(e.remoteServer, equals(normal.host));
        expect(e.remotePort, equals(badPort));
        expect(e.localPort, isNotNull);
      }
    });

    test('using LDAPS on non-existant port', () async {
      var bad =
          LdapConnection(host: secure.host, ssl: secure.ssl, port: badPort);

      try {
        await bad.open();
        expect(false, isTrue);
      } on LdapSocketRefusedException catch (e) {
        expect(e.remoteServer, equals(normal.host));
        expect(e.remotePort, equals(badPort));
        expect(e.localPort, isNotNull);
      }
    });
  });

  //----------------------------------------------------------------

  group('Simple LDAP bind', () {
    //----------------

    test('Simple Bind', () async {
      var ldap = LdapConnection(
          host: normal.host,
          ssl: normal.ssl,
          port: normal.port,
          bindDN: normal.bindDN,
          password: normal.password);

      expect(ldap.isBound, isFalse);
      expect(ldap.state, equals(ConnectionState.closed));

      // Open connection

      await ldap.open();

      expect(ldap.isBound, isFalse);

      // Bind

      var result = await ldap.bind();
      expect(result, const TypeMatcher<LdapResult>());
      expect(result.resultCode, equals(ResultCode.OK));

      expect(ldap.isBound, isTrue);
      expect(ldap.state, equals(ConnectionState.bound));
      // Close

      await ldap.close();

      expect(ldap.isBound, isFalse);
      expect(ldap.state, equals(ConnectionState.closed));
    });

    //----------------

    test('with bad DN fails', () async {
      var ldap = LdapConnection(
          bindDN: 'uid=badDN',
          host: normal.host,
          ssl: normal.ssl,
          port: normal.port);

      expect(ldap.isBound, isFalse);
      expect(ldap.state, equals(ConnectionState.closed));

      await ldap.open();
      expect(ldap.isBound, isFalse);
      expect(ldap.state, equals(ConnectionState.ready));

      try {
        await ldap.bind();
        fail('Expected bad bind() credentials to throw an error');
      } catch (e) {
        expect(e, const TypeMatcher<LdapResultInvalidCredentialsException>());
      }
    });

    //----------------

    test('with bad password fails', () async {
      var ldap = LdapConnection(
          password: 'badPassword!!',
          host: normal.host,
          ssl: normal.ssl,
          port: normal.port);

      expect(ldap.isBound, isFalse);
      expect(ldap.state, equals(ConnectionState.closed));

      await ldap.open();

      expect(ldap.isBound, isFalse);
      expect(ldap.state, equals(ConnectionState.ready));

      // Bind

      try {
        await ldap.bind();
        fail('Expected bad password to throw an exception');
      } catch (e) {
        expect(e, const TypeMatcher<LdapResultInvalidCredentialsException>());
      }
    });
  }); // end group
}
