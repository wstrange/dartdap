import 'package:unittest/unittest.dart';
import 'package:dartdap/dartdap.dart';
import 'package:quiver/async.dart';
import 'package:quiver/iterables.dart';
import 'dart:math' as Math;

const int NUM_ENTRIES = 2000;

var dn = new DN("ou=People,dc=example,dc=com");

main() {

  var ldapConfig = new LDAPConfiguration('ldap.yaml','default');
  initLogging();

  group('Test group', ()  {
    LDAPConnection ldap;

    setUp( ()  async {
      ldap =  await ldapConfig.getConnection();
    });

    tearDown( () {
      return ldapConfig.close();
    });

    // this is designed to clean up any failed tests
    test('delete previous entries from last run', ()=> _deleteEntries(ldap));

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

     // bit of a hack. Note the directory has a max limit
     // for the number of results returned. 1000 is teh default for DJ
     var expected = Math.min(NUM_ENTRIES,1000);

     // todo - use listen onDone: to hook in
     return ldap.search("ou=People,dc=example,dc=com",f,["uid","sn"]).
          listen((SearchEntry entry) {
           //logMessage("${entry} ");
           count += 1;
          },
         onDone: () => expect(count, equals(expected) ),
         onError: (LDAPResult r) {
           if( r.resultCode == ResultCode.SIZE_LIMIT_EXCEEDED && count == expected )  {
             logger.info("got expected size result error $r");
           }
           else
             fail("Unexpected LDAP error $r");
         });
   });

   // run this to clean up entries
   test('delete entries', () => _deleteEntries(ldap));

  }); // end group

}

// purge entries from the test
_deleteEntries(ldap) {
  return forEachAsync( range(NUM_ENTRIES),  (j) {
           var d = dn.concat("uid=test$j");
           // ignore any errors - we dont really care
           return ldap.delete(d.dn).then( (_) => _, onError: (_) => true);
       });
}

