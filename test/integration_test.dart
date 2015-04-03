import 'package:unittest/unittest.dart';
import 'package:dartdap/dartdap.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';


/**
 * LDAP integration tests
 *
 * These tests assume the LDAP server is pre-populated with some
 * sample entries - currently created by the OpenDJ installer.
 *
 * TODO: Have the integration test create its pre-req entries.
 */

main() async {
  LDAPConnection ldap;
  var ldapConfig = new LDAPConfiguration.fromFile("test/ldap.yaml","default");

  startQuickLogging();

  group('LDAP Integration ', ()  {
    // create a connection. Return a future that completes when
    // the connection is available and bound
    setUp( ()  async {
     ldap = await ldapConfig.getConnection();
    });

    tearDown( () {
      // nothing to do. We can keep the connection open between tests
    });

    test('Search Test', () {
     var attrs = ["dn", "cn", "objectClass"];

     ldap.onError = expectAsync((e) => expect(false, 'Should not be reached'), count: 0);

     var filter = Filter.substring("cn=A*");

      // we expect to find entries starting with A in the directory root.
     ldap.search("dc=example,dc=com", filter, attrs).stream
       .listen( (SearchEntry entry) {
         // expected.
          //print("Found ${entry}");
        });

     var notFilter = Filter.not(filter);


      // we expect to find non A entries
     ldap.search("dc=example,dc=com", notFilter, attrs).stream
      .listen( (SearchEntry entry) {
         //print("Not search = ${entry}");
         // todo: test entries.
      });

     // bad search

     ldap.search("dn=foofoo", notFilter, attrs).stream
      .listen(
          expectAsync( (r) => print("should not be called!"), count:0),
          onError: expectAsync( (e) =>  expect( e.resultCode, equals(ResultCode.NO_SUCH_OBJECT)))
      );

      //  ));
   });


   test('add/modify/delete request', () async {
      var dn = "uid=mmouse,ou=People,dc=example,dc=com";

      // clean up any previous failed test. We don't care about the result
      try {
        await ldap.delete(dn);
      } catch(e) {};

      var attrs = { "cn" : "Mickey Mouse", "uid": "mmouse", "sn":"Mouse",
                    "objectClass":["inetorgperson"]};

      // add mickey
      var result = await ldap.add(dn, attrs);
      expect( result.resultCode, equals(0));
      // modify mickey's sn
      var m = new Modification.replace("sn", ["Sir Mickey"]);
      result = await ldap.modify(dn, [m]);
      expect(result.resultCode,equals(0));
      // finally delete mickey
      result = await ldap.delete(dn);
      expect(result.resultCode,equals(0));
   }); // end test

   test('test error handling', () async {

     // dn we know will fail to delete as it does not exist
     var dn = "uid=FooDoesNotExist,ou=People,dc=example,dc=com";

     try {
       await ldap.delete(dn);
       fail("Should not be able to delete a non existing DN");
     }
     catch (e) {
       expect( e.resultCode, equals(ResultCode.NO_SUCH_OBJECT));
     }
  });


   test('Modify DN', () async {
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

     var r =  await ldap.add(dn, attrs); // create mmouse
     expect( r.resultCode, equals(0));
     r = await ldap.modifyDN(dn,"uid=mmouse2"); // rename to mmouse2
     expect( r.resultCode, equals(0));
     // try to rename and reparent
     r = await ldap.modifyDN(renamedDN,newrdn,false,newParent);
     expect( r.resultCode, equals(0));
     r = await ldap.delete(renamedDN2);
     expect( r.resultCode, equals(0));
   });

  // test ldap compare operation. This assumes OpenDJ has been
  // populated with the sample user: user.0
  test('Compare test',()  async {
    String dn = "uid=user.0,ou=People,dc=example,dc=com";

    var r = await ldap.compare(dn, "postalCode", "50369");
    expect( r.resultCode, equals(ResultCode.COMPARE_TRUE));
  });

  }); // end group

  test('clean up', () => ldapConfig.close() );

}
