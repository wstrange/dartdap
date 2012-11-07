

import 'package:unittest/unittest.dart';


import 'package:dartdap/ldap_client.dart';
import 'package:asn1lib/asn1lib.dart';

import 'dart:scalarlist';
import 'dart:math';
import 'dart:isolate';


main() {
  //var dn = "cn=test";
  var dn = "cn=Directory Manager";
  var pw = "password";

  
  initLogging();

  

 test('Search Test', () {
   var attrs = ["dn", "cn", "objectClass"];
   
   var c = new LDAPConnection("localhost", 1389,dn,pw);
   c.onError = (e) {
     print("Got exception ${e}");
   };

   var fb  = c.bind(); 
   
   fb.then( (r) { print("Bind happend"); });
   

   var sb = c.search("dc=example,dc=com", "(objectClass=*)", attrs);
   /**
   
   var t = new Timer(3000, (Timer t) {
  
    var sb = c.search("dc=example,dc=com", "(objectClass=*)", attrs);
   });
   */
   
   /*
   sb.then( (SearchResults sr) {
      sr.foreach(.....);
     print("Got LDAP result");
   });
   */
   
   
  });
 
}
