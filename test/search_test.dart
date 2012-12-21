

import 'package:unittest/unittest.dart';
import 'package:dartdap/ldap_client.dart';

import 'dart:scalarlist';
import 'dart:math';
import 'dart:isolate';


main() {
  //var dn = "cn=test";
  var dn = "cn=Directory Manager";
  var pw = "password";

  var c = new LDAPConnection("localhost", 1389,dn,pw);


  group('Test group', () {
    setUp( () {
      initLogging();
      var fb  = c.bind();
      fb.then( (r) { print("LDAP Connection Bind"); });
    });

    tearDown( () {
      print("Closing ");
      c.close();
    });



    test('Search Test', () {
     var attrs = ["dn", "cn", "objectClass"];


     c.onError = expectAsync1((e) => expect(false, 'Should not be reached'), count: 0);


     var filter = Filter.substring("cn=A*");


     var sb = c.search("dc=example,dc=com", filter, attrs);

    // todo: define SearchResult
     sb.then( expectAsync1( (SearchResult r) {
           print("Search Completed r = ${r}");
         }, count: 1));

     var notFilter = Filter.not(filter);

     sb = c.search("dc=example,dc=com", notFilter, attrs);
     /*-------------------
     sb.then( expectAsync1( (SearchResult r) {
       print("Not Search Completed r = ${r}");
     }, count: 1));

  */
    //c.close();

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

   solo_test('add/del request', () {

      var dn = "uid=mmouse,ou=People,dc=example,dc=com";
      var objclass = new Attribute("objectClass");
      objclass.addValue("inetorgperson");


      c.delete(dn).then( (result) {
        print("delete result= $result");
      });


      var attrs = [ new Attribute.simple("cn", "Mickey Mouse"),
                    new Attribute.simple("uid", "mmouse"),
                    new Attribute.simple("sn", "mouse"),
                    //new Attribute.simple("dn", dn),
                    objclass];

      c.add(dn, attrs).then( (r) {
        print("Result = $r");
      });



   }); // end test

  }); // end group


}
