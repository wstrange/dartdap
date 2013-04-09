

import 'package:unittest/unittest.dart';
import 'package:dartdap/ldap_client.dart';


import 'dart:math';
import 'dart:isolate';
import 'dart:async';


main() {
  LDAPConnection ldap;

  var ldapConfig = new LDAPConfiguration("test/ldap.yaml");

  initLogging();

  group('LDAP Integration  group', () {
    setUp( () {

      return ldapConfig.getConnection()
          .then( (LDAPConnection l) => ldap =l );
    });

    tearDown( () {
      print("Closing ...");
      ldap.close(true);
    });

    solo_test('Search Test', () {
     var attrs = ["dn", "cn", "objectClass"];

     ldap.onError = expectAsync1((e) => expect(false, 'Should not be reached'), count: 0);

     var filter = Filter.substring("cn=A*");


     var sb = ldap.search("dc=example,dc=com", filter, attrs);

    // todo: define SearchResult
     sb.then( expectAsync1( (SearchResult r) {
           print("Search Completed r = ${r}");
         }, count: 1));

     var notFilter = Filter.not(filter);

     sb = ldap.search("dc=example,dc=com", notFilter, attrs);
     /*-------------------
     sb.then( expectAsync1( (SearchResult r) {
       print("Not Search Completed r = ${r}");
     }, count: 1));

  */
    //c.close();

   });


   test('add/modify/delete request', () {
      var dn = "uid=mmouse,ou=People,dc=example,dc=com";

      // clean up first from any failed test
      ldap.delete(dn).then( (result) {
        print("delete result= $result");
      }).catchError( (e) {
        print("delete result ${e.error.resultCode}");
      });

      var attrs = { "cn" : "Mickey Mouse", "uid": "mmouse", "sn":"Mouse",
                    "objectClass":["inetorgperson"]};

      // add mickey to directory
      ldap.add(dn, attrs).then( expectAsync1((r) {
        expect( r.resultCode, equals(0));
        // modify mickey's sn
        var m = new Modification.replace("sn", ["Sir Mickey"]);
        ldap.modify(dn, [m]).then( expectAsync1((result) {
          expect(result.resultCode,equals(0));
          // finally delete mickey
          ldap.delete(dn).then( expectAsync1((result) {
            expect(result.resultCode,equals(0));
          }));
        }));
      }));


   }); // end test

   test('test error handling', () {

     var dn = "uid=FooDoesNotExist,ou=People,dc=example,dc=com";

     ldap.errorOnNonZeroResult = false;

     ldap.delete(dn).then(  (result) {
       expect( result.resultCode , greaterThan(0) );
     }).catchError( (result) {
       fail('catchError should not have been called');
     });

     ldap.errorOnNonZeroResult = true;

     ldap.delete(dn).then(  (result) {
       fail('Future catchError should have been called');
     }).catchError( ( e) {
       expect( e.error.resultCode, greaterThan(0));
     });
   }); // end test

  }); // end grou

}
