import 'package:unittest/unittest.dart';
import 'package:dartdap/dartdap.dart';
import 'package:quiver/async.dart';
import 'package:quiver/iterables.dart';

import 'dart:async';

const int NUM_ENTRIES = 50;

var dn = new DN("ou=People,dc=example,dc=com");

main() {

  var ldapConfig = new LDAPConfiguration('ldap.yaml','default');
  initLogging();

  group('Test group', () {
    LDAPConnection ldap;

    setUp( () {
      return ldapConfig.getConnection()
          .then( (LDAPConnection l) => ldap =l );
    });

    tearDown( () {
      return ldapConfig.close();
    });

    test('delete previous entries from last run', () {

      return forEachAsync( range(NUM_ENTRIES),  (j) {
        var d = dn.concat("uid=test$j");
        // ignore any errors - we dont really care
        return ldap.delete(d.dn).then( (_) => print('delete $d'), onError: (_) => true);
      });
    });

   /**
    * Add a number of entries
    */
   test('bulk add', () {
     return forEachAsync( range(NUM_ENTRIES), (i) {
      var attrs = { "sn":"test$i", "cn":"Test user$i",
                          "objectclass":["inetorgperson"]};
      return ldap.add("uid=test$i,ou=People,dc=example,dc=com", attrs);
      });
   });


   test('search for entries', () {
     int count = 0;
     var f = Filter.substring("uid=test*");

     // todo - use listen onDone: to hook in
     return ldap.search("ou=People,dc=example,dc=com",f,["uid","sn"]).
          listen((SearchEntry entry) {
           logMessage("${entry} ");
           count += 1;
          },
         onDone: () => expect(count, equals(NUM_ENTRIES) ) );
   });

  }); // end group

}
