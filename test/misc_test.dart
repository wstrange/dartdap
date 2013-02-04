

import 'package:unittest/unittest.dart';


import 'package:dartdap/ldap_client.dart';
import 'package:asn1lib/asn1lib.dart';

import 'package:dartdap/src/protocol/ldap_protocol.dart';

import 'dart:scalarlist';
import 'dart:math';
import 'dart:isolate';


main() {


  test("Escape ldap search string test", () {
    expect(LDAPUtil.escapeString("F*F"), equals('F\\2aF'));
    expect(LDAPUtil.escapeString("\\"), equals("\\5c"));
    expect(LDAPUtil.escapeString("(cn=foo*)"), equals("\\28cn=foo\\2a\\29"));

  });


  test("LDAP Filter composition ", () {
    //var xx = Filter.substring("cn=foo");

    var f1 = new SubstringFilter("cn=foo*");
    expect(f1.any, isEmpty );
    expect(f1.initial, equals("foo"));
    expect(f1.finalString,isNull);


    var f2 = new SubstringFilter("cn=*bar");
    expect(f2.initial,isNull);
    expect(f2.any,isEmpty);
    expect(f2.finalString, equals("bar"));


    var c1 =  f1 & f2;

    print(c1.toString());


  });



}