

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


   solo_test('add/modify/delete request', () {
      var dn = "uid=mmouse,ou=People,dc=example,dc=com";
      var objclass = new Attribute("objectClass");
      objclass.addValue("inetorgperson");

      // clean up first from any failed test
      c.delete(dn).then( (result) {
        print("delete result= $result");
      }).catchError( (e) {
        print("delete result ${e.error.resultCode}");
      });


      var attrs = [ new Attribute.simple("cn", "Mickey Mouse"),
                    new Attribute.simple("uid", "mmouse"),
                    new Attribute.simple("sn", "mouse"),
                    objclass];

      c.add(dn, attrs).then( expectAsync1((r) {
        expect( r.resultCode, equals(0));

        var m = new Modification.replace("sn", ["Sir Mickey"]);
        c.modify(dn, [m]).then( expectAsync1((result) {
          expect(result.resultCode,equals(0));

          c.delete(dn).then( expectAsync1((result) {
            expect(result.resultCode,equals(0));
          }));
        }));
      }));


   }); // end test

   test('test error handling', () {

     var dn = "uid=FooDoesNotExist,ou=People,dc=example,dc=com";

     c.errorOnNonZeroResult = false;

     c.delete(dn).then(  (result) {
       expect( result.resultCode , greaterThan(0) );
     }).catchError( (result) {
       fail('catchError should not have been called');
     });

     c.errorOnNonZeroResult = true;

     c.delete(dn).then(  (result) {
       fail('Future catchError should have been called');
     }).catchError( ( e) {
       expect( e.error.resultCode, greaterThan(0));
     });


   }); // end test

  }); // end group


}
