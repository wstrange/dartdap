import 'package:unittest/unittest.dart';
import 'package:dartdap/dartdap.dart';
import 'dart:math' as Math;
import 'package:logging_handlers/logging_handlers_shared.dart';


const int NUM_ENTRIES = 2000;

var dn = new DN("ou=People,dc=example,dc=com");

main() {

  var ldapConfig = new LDAPConfiguration.fromFile('test/ldap.yaml','default');
  startQuickLogging();


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
   test('bulk add', () async {
     for(int i=0; i < NUM_ENTRIES; ++i) {
       var attrs = { "sn":"test$i", "cn":"Test user$i",
                                "objectclass":["inetorgperson"]};
       var result = await ldap.add("uid=test$i,ou=People,dc=example,dc=com", attrs);
       expect(result.resultCode, equals(0));
     }
   });


   test('search for entries', () {
     int count = 0;
     var f = Filter.substring("uid=test*");

     // bit of a hack. Note the directory has a max limit
     // for the number of results returned. 1000 is teh default for DJ
     var expected = Math.min(NUM_ENTRIES,1000);

     // todo - use listen onDone: to hook in
     return ldap.search("ou=People,dc=example,dc=com",f,["uid","sn"]).stream.
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

// purge entries from the test to clean up
_deleteEntries(ldap) async {
  for(int j=0; j < NUM_ENTRIES; ++j) {
    // ignore any errors - we dont really care
    try {
      await ldap.delete((dn.concat("uid=test$j")).dn);
    } catch(e) {};
  }
}

