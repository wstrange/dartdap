

import 'package:unittest/unittest.dart';


import 'package:dartdap/ldap_client.dart';
import 'package:asn1lib/asn1lib.dart';

import 'package:dartdap/src/protocol/ldap_protocol.dart';

import 'dart:scalarlist';
import 'dart:math';
import 'dart:isolate';


main() {
  
  
  test("Escape ldap search string test", () {
    expect( LDAPUtil.escapeString("F*F"), equals('F\\2aF'));
    expect(LDAPUtil.escapeString("\\"), equals("\\5c"));
    expect(LDAPUtil.escapeString("(cn=foo*)"), equals("\\28cn=foo\\2a\\29"));
    
  });
  
}