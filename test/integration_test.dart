

import 'package:unittest/unittest.dart';
import 'package:dartdap/ldap_client.dart';


import 'dart:math';
import 'dart:isolate';
import 'dart:async';


main() {
  LDAPConnection ldap;
  var ldapConfig = new LDAPConfiguration("test/ldap.yaml");

  initLogging();

  group('LDAP Integration ', () {
    // create a connection. Return a future that completes when
    // the connection is available and bound
    setUp( () {
      return ldapConfig.getConnection()
          .then( (LDAPConnection l) => ldap =l );
    });

    tearDown( () {
      // nothing to do. We keep the connection open
    });

    test('Search Test', () {
     var attrs = ["dn", "cn", "objectClass"];

     ldap.onError = expectAsync1((e) => expect(false, 'Should not be reached'), count: 0);

     var filter = Filter.substring("cn=A*");


     ldap.search("dc=example,dc=com", filter, attrs)
       .listen( (SearchEntry entry) {
          //print("Found ${entry}");
        });

     var notFilter = Filter.not(filter);

     ldap.search("dc=example,dc=com", notFilter, attrs)
      .listen( (SearchEntry entry) {
         //print("Not search = ${entry}");
      });

     // bad search

     ldap.search("dn=foofoo", notFilter, attrs)
      .listen(
          expectAsync1( (r) => print("should not be called!"), count:0),
          onError: expectAsync1( (e) =>  expect( e.resultCode, equals(ResultCode.NO_SUCH_OBJECT)))
      );

      //  ));


   });


   test('add/modify/delete request', () {
      var dn = "uid=mmouse,ou=People,dc=example,dc=com";

      // clean up first from any failed test. We don't care about the result
      ldap.delete(dn).then( (result) {
        //print("delete result= $result");
      }).catchError( (e) {
        //print("delete result ${e.error.resultCode}");
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

     // dn we know will fail to delete as it does not exist
     var dn = "uid=FooDoesNotExist,ou=People,dc=example,dc=com";

     ldap.delete(dn)
      .then( expectAsync1( (r) {
          expect(false,'Future catchError should have been called');
          }, count:0))
      .catchError( expectAsync1( (e) {
        expect( e.resultCode, equals(ResultCode.NO_SUCH_OBJECT));
      }));

   }); // end test


   test('Modify DN', () {
     var dn = "uid=mmouse,ou=People,dc=example,dc=com";
     var newrdn = "uid=mmouse2";
     var renamedDN =  "uid=mmouse2,ou=People,dc=example,dc=com";
     var renamedDN2 =  "uid=mmouse2,dc=example,dc=com";

     var newParent = "dc=example,dc=com";

     var attrs = { "cn" : "Mickey Mouse", "uid": "mmouse", "sn":"Mouse",
                   "objectClass":["inetorgperson"]};

     /*
        For some reason OUD does not seem to respect the deleteOldRDN flag
        It always moves the entry - and does not leave the old one

     */
     ldap.add(dn, attrs)
       .then( (r) => ldap.modifyDN(dn,newrdn))
       .then(expectAsync1((r) {
         expect( r.resultCode, equals(0));
        }))
        .then( (_) => ldap.modifyDN(renamedDN,newrdn,false,newParent))
        .then( expectAsync1(((r) {
         expect( r.resultCode, equals(0));
        })))
        .then( (_) => ldap.delete(renamedDN2));
   });

  // todo: make the compare test against a known value.
  solo_test('Compare test',() {
    String dn = "uid=user.0,ou=People,dc=example,dc=com";

    ldap.compare(dn, "postalCode", "50369").then((r) {
      expect( r.resultCode, equals(ResultCode.COMPARE_TRUE));
      print('compare ok');

     });
  });

  }); // end grou
}
