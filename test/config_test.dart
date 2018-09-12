// Tests for LDAPConfiguration
//
// These tests do not use a LDAP server. They only test the LDAP configuration, and not
// the connection to an LDAP server with those settings.
//
// Requirements: the "test/configuration_test.yaml" file


import 'dart:math';
import 'package:test/test.dart';

import 'package:dartdap/dartdap.dart';
import 'test_configuration.dart';



const String CONFIG_FILE = "test/TEST-config.yaml";

void main() {

  test("simple configuration test", (){
    var config = new TestConfiguration(CONFIG_FILE);

    var c = config.connections["opendj"];

    expect(c.port, equals(1389));

  });
}
