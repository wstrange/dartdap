

import 'package:unittest/unittest.dart';


import 'package:dartdap/ldap_client.dart';
import 'package:asn1lib/asn1lib.dart';

import 'dart:scalarlist';
import 'dart:math';


main() {
  //var dn = "cn=test";
  var dn = "cn=Directory Manager";
  var pw = "password";

  
  initLogging();

 
  
  test('Ldap Bind test', () {
   
    //_logger.fine("Test LOGGING ********");
    
    var c = new LDAPConnection("localhost", 1389,dn,pw);
  
    var f = c.bind();
   
    f.then( (LDAPResult r) {
      print("Bind Completed with ${r}");
    });
    
    c.close();
    
  });
  
 test('Ldap Bind to non existing server', () {
    
    var c = new LDAPConnection("no-server-localhost", 21389,dn,pw);
  
    bool hadError = false;
    c.onError = (e) {
      print("Got exception ${e}");
    };
    
    c.close();
    
  });
 
 
 
}
