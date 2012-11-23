

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
   
   c.onError = expectAsync1((e) => expect(false, 'Should not be reached'), count: 0);
 
 
 /*
   c.onError = (e) {
     print("Got exception ${e}");
     fail("Unexpected exception");
   };
   */

   var fb  = c.bind(); 
   
   fb.then( (r) { print("Bind happend"); });
   
   /*
    * This style is crap:
   Filter f = new Filter.not(new Filter.equals("objectClass",'inetOrgPerson'));
   
   
   use static methods...
   
      Filter.and( [Filter.not(Filter.equals("foo","bar")), Filter.presence("cn")]);
      
   operator overloading with +, =, &
   
   new Filter.s();
   
     ! ( Filter.present("cn") & Filter.equals("cn","bar")) 
          
   
   new Filter()..present("cn")
    
   */
   
   //var complexFilter =  Filter.substring("cn=bar*") & 

   //var sb = c.search("dc=example,dc=com", f, attrs);
   /*
   sb.then( (SearchResult r) {
     print("Search Completed r = ${r}");
   });
   */
   /*
   sb.then( expectAsync1( 
       (SearchResult r) {
         print("Search Completed r = ${r}");
       }, count: 1));
   
  c.close();
  */
 });
 

 solo_test("LDAP Filter composition ", () {
   
   var f1 = new SubstringFilter("cn=foo*");
   expect(f1.any, isEmpty );
   expect(f1.initial.stringValue, equals("foo"));
   expect(f1.finalStr,isNull);
   
   
   var f2 = new SubstringFilter("cn=*bar");
   expect(f2.initial,isNull);
   expect(f2.any,isEmpty);
   expect(f2.finalStr.stringValue, equals("bar"));
   
  
   
   var c1 =  f1 & f2; 
   
   print(c1.toString());
   
   
 });
 
 
}
