

import 'package:unittest/unittest.dart';
import 'package:dartdap/ldap_client.dart';

import 'dart:scalarlist';
import 'dart:math';
import 'dart:isolate';


main() {
  //var dn = "cn=test";
  var dn = "cn=Directory Manager";
  var pw = "password";
  LDAPConnection c;


  group('Test group', () {
    setUp( () {
      initLogging();
      print("Create connection");
      c = new LDAPConnection("localhost", 1389,dn,pw);
      var fb  = c.bind();
      fb.then( (r) { print("LDAP Connection Bind"); });

      c.onError = (e) { print("Connection error $e"); };
    });

    tearDown( () {
      print("Closing ...");
      c.close();
    });

   test('bulk add', () {
      var dn = new DN("ou=People,dc=example,dc=com");

     // clean up
     for( int i=0; i < 100; ++i) {
       var d = dn.concat("uid=test$i");
       c.delete(d.dn).then( (r) {
         //print("delete result=${r.resultCode}");
       }, onError: (e) {
         print("Error result - ignored ${e.error.resultCode}");
       });
     }


     for( int i=0; i < 100; ++i ) {
       var attrs = { "sn":"test$i", "cn":"Test user$i",
                     "objectclass":["inetorgperson"]};
       c.add("uid=test$i,ou=People,dc=example,dc=com", attrs).then( (r) {
         expect(r.resultCode,equals(0));
       });
     }

     c.search("ou=People,dc=example,dc=com",
         Filter.substring("uid=test*"), ["uid","sn"]).then( (SearchResult result) {
           //print("Got result= ${result}");
           //result.searchEntries.forEach((e) {print(e);} );
         });

   });

  }); // end group


}
