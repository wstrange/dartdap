

import 'package:unittest/unittest.dart';
import 'package:dartdap/ldap_client.dart';

import 'dart:math';
import 'dart:isolate';


main() {
  LDAPConnection ldap;
  var ldapConfig = new LDAPConfiguration('test/ldap.yaml');


  initLogging();

  group('Test group', () {
    setUp( () {
      return ldapConfig.getConnection()
          .then( (LDAPConnection l) => ldap =l );
    });

    tearDown( () {

      //ldap.close();
    });

   test('bulk add', () {
      var dn = new DN("ou=People,dc=example,dc=com");

     // clean up
     for( int i=0; i < 100; ++i) {
       var d = dn.concat("uid=test$i");
       ldap.delete(d.dn).then( (r) {
         //print("delete result=${r.resultCode}");
       }, onError: (e) {
         print("Error result - ignored ${e.error.resultCode}");
       });
     }


     for( int i=0; i < 100; ++i ) {
       var attrs = { "sn":"test$i", "cn":"Test user$i",
                     "objectclass":["inetorgperson"]};
        ldap.add("uid=test$i,ou=People,dc=example,dc=com", attrs).then( (r) {
          expect(r.resultCode,equals(0));
        });
     }

     ldap.search("ou=People,dc=example,dc=com",
         Filter.substring("uid=test*"), ["uid","sn"]).listen( (SearchEntry entry) {
           print("Got entry= ${entry}");
         });

   });

  }); // end group


}
