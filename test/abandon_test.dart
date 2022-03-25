// Tests abandonRequest
//
//----------------------------------------------------------------

import 'dart:async';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import 'util.dart' as util;


void runTests(util.ConfigDirectory configDirectory) {
  late LdapConnection ldap;

  setUp(() async {
    ldap = configDirectory.getConnection();
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
    for(var i=0; i < 5; ++i) {
      await Future.delayed(Duration(seconds: 1));
      ldap.abandonRequest(messageId: 0);
    }
  });

  test('Abandon on an unbound connection should work OK', () async {
    await ldap.close();
    await ldap.open();

    for(var i=0; i < 5; ++i) {
      await Future.delayed(Duration(seconds: 1));
      ldap.abandonRequest(messageId: 0);
    }
  });
}

void main() {
  final config = util.Config();

  group('abandon test', () {
    runTests(config.directory(util.ldapsDirectoryName));
  }, skip: config.skipIfMissingDirectory(util.ldapsDirectoryName));
}
