// Tests abandonRequest
//
//----------------------------------------------------------------

import 'dart:async';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import 'util.dart';

void main() {
  late LdapConnection ldap;

  setUpAll(() async {
    ldap = defaultConnection(ssl: true);
  });

  setUp(() async {
    await ldap.open();
    await ldap.bind();
    // Nothing to populate, since these tests exercise the 'add' operation
  });

  tearDown(() async {
    await ldap.close();
  });

  test('send abandon should not throw exception', () async {
    ldap.abandonRequest(messageId: 0);
    await Future.delayed(Duration(seconds: 1));
  });

  test('Send periodic abandon requests to simulate keep-alive', () async {
    for (var i = 0; i < 5; ++i) {
      await Future.delayed(Duration(seconds: 1));
      ldap.abandonRequest(messageId: 0);
    }
  });

  test('Abandon on an unbound connection should work OK', () async {
    await ldap.close();
    await ldap.open();

    for (var i = 0; i < 5; ++i) {
      await Future.delayed(Duration(seconds: 1));
      ldap.abandonRequest(messageId: 0);
    }
  });
}
