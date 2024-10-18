// Tests connection open, close and bind.
//
//----------------------------------------------------------------

import 'dart:async';
import 'dart:io';

import 'package:dartdap/dartdap.dart';
import 'package:test/test.dart';

import 'setup.dart';

/// Not all ldap servers allow anonymous search
///
/// If the LDAP directory used for testing does not allow anonymous searches,
/// set this to false and the tests that perform an anonymous search will be
/// skipped. Set it to true to include those tests.

var allowAnonymousSearch = true;

final testDN = DN('dc=example,dc=com');

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
      await ldap.search(testDN, filter, searchAttrs, sizeLimit: 100);
  var ldapResult = await searchResults.getLdapResult();
  print('bound = ${ldap.isBound}  ssl= ${ldap.isSSL} $ldapResult');
  await for (SearchEntry entry in searchResults.stream) {
    expect(entry, isNotNull);
    expect(entry, const TypeMatcher<SearchEntry>());
    print('got entry $entry');
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
  // Get the configurations for the two types of connections

  final normal = defaultConnection(ssl: false);
  final secure = defaultConnection(ssl: true);

  //================================================================
  group(
    'connect succeeds',
    () {
      test('close test', () async {
        var ldap = normal;

        expect(ldap.state, equals(ConnectionState.closed));
        expect(ldap.isBound, isFalse);

        await ldap.open();

        expect(ldap.state, equals(ConnectionState.ready));
        expect(ldap.isBound, isFalse);

        // LDAP operations can be performed on an open connection
        await doLdapOperation(ldap, testDN);

        // Close the connection

        await ldap.close();

        expect(ldap.state, equals(ConnectionState.closed));
        expect(ldap.isBound, isFalse);
      });

      //----------------

      test('using LDAPS', () async {
        var ldaps = secure;
        // Note: setting badCertificateHandler to accept test certificate

        expect(ldaps.state, equals(ConnectionState.closed));
        expect(ldaps.isBound, isFalse);

        // Open anonymous connection

        await ldaps.open();

        expect(ldaps.state, equals(ConnectionState.ready));
        expect(ldaps.isBound, isFalse);

        // LDAP operations can be performed on an open connection

        await doLdapOperation(ldaps, testDN);

        // Close connection

        await ldaps.close();

        expect(ldaps.state, equals(ConnectionState.closed));
        expect(ldaps.isBound, isFalse);
      });
    },
  );

  group('authenticated', () {
    test('using LDAP', () async {
      var ldap = normal;

      await _doBind(ldap, testDN);
    });

    //----------------

    test('using LDAPS', () async {
      var ldaps = secure;

      await _doBind(ldaps, testDN);
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
        // , skip: 'this never fails and the test times out'
        );
    */

    //----------------
  });

  //----------------------------------------------------------------

  group('TCP/IP socket fails', () {
    test('using LDAP on non-existant host', () async {
      var bad = LdapConnection(host: 'badHost', ssl: false, port: 1389);

      try {
        await bad.open();
        fail('should not get here');
      } on LdapSocketServerNotFoundException catch (e) {
        // TODO: confirm behavior and fix dartdap if necessary
        //
        // Previously, LdapSocketRefusedException was expected and
        // LdapSocketServerNotFoundException was commented out.
        //
        // LdapSocketServerNotFoundException is thrown when connecting
        // to an OpenLDAP server (from Dart 2.8.4 on macOS connecting to
        // OpenLDAP running on CentOS 7.2). Does it throw
        // LdapSocketRefusedException with a different setup?

        // expect(e, const TypeMatcher<LdapSocketRefusedException>());
        expect(e.remoteServer, equals('badHost'));
      }
    });

    test('using LDAPS on non-existent host', () async {
      var bad = LdapConnection(host: 'badHost', ssl: true, port: 1636);
      try {
        await bad.open();
        expect(false, isTrue);
      } catch (e) {
        // TODO:  confirm behavior and fix dartdap if necessary (see above)

        expect(e, const TypeMatcher<LdapSocketServerNotFoundException>());
        //expect(e, const TypeMatcher<LdapSocketRefusedException>());
        //expect(e, hasProperty('remoteServer', badHost));
      }
    });

    test('using LDAP on non-existent port', () async {
      var bad = LdapConnection(host: 'localhost', ssl: false, port: 6666);

      try {
        await bad.open();
        expect(false, isTrue);
      } on LdapSocketRefusedException catch (e) {
        expect(e.remoteServer, equals(normal.host));
        expect(e.remotePort, equals(6666));
        expect(e.localPort, isNotNull);
      }
    });

    test('using LDAPS on non-existent port', () async {
      var bad = LdapConnection(host: 'localhost', ssl: true, port: 6666);

      try {
        await bad.open();
        expect(false, isTrue);
      } on LdapSocketRefusedException catch (e) {
        expect(e.remoteServer, equals(normal.host));
        expect(e.remotePort, equals(6666));
        expect(e.localPort, isNotNull);
      }
    });
  });

  //----------------------------------------------------------------

  group('Simple LDAP bind', () {
    //----------------

    test('Simple Bind', () async {
      var ldap = defaultConnection(ssl: false);

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

    test('with bad credentialsfails', () async {
      var ldap = LdapConnection(
          bindDN: DN('uid=badDN'),
          password: 'foo',
          host: 'localhost',
          ssl: false,
          port: 1389);

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
  }); // end group
}
