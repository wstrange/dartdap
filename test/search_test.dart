import 'package:unittest/unittest.dart';
import 'package:dartdap/dartdap.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:logging/logging.dart';


/**
 * LDAP search tests
 *
 * These tests assume the LDAP server is pre-populated with some
 * sample entries - currently created by the OpenDJ installer.
 *
 * TODO: Have the integration test create its pre-req entries.
 */

main()  {
  LDAPConnection ldap;
  var ldapConfig = new LDAPConfiguration("ldap.yaml","default");

  startQuickLogging();
  Logger.root.level = Level.ALL;

  group('LDAP Integration ', ()  {
    // create a connection. Return a future that completes when
    // the connection is available and bound
    setUp( ()  async {
     ldap = await ldapConfig.getConnection();
    });

    tearDown( () async {
      // nothing to do. We can keep the connection open between tests
      //await ldap.close();
      return ldap.close();
    });


    test('VLV Search2', () {
         var slist = [new SortKey("sn")];

         var sortControl = new ServerSideSortRequestControl(slist);
         var vlvControl = new VLVRequestControl.offsetControl(1, 0, 0, 1, null);

         // using OpenDJ ldapsearch command:
         // ldapsearch -p 1389 -b "ou=people,dc=example,dc=com" -s one -D "cn=Directory Manager" -w password
         // -G 0:1:1:0 --sortOrder sn "objectclass=inetOrgPerson"
         //var filter = Filter.substring("cn=Ac*");
         //var filter = Filter.or( [Filter.equals("givenName", "A"), Filter.equals("sn", "Annas")]);
         var filter =  Filter.equals("objectclass", "inetOrgPerson");
         var result = ldap.search("dc=example, dc=com", filter, ["sn","cn","uid","mail"], controls:[sortControl,vlvControl]);


         return result.stream.listen( (SearchEntry entry)
            =>  info('======== entry: $entry'),

              onDone: () => info('======== Controls: ${result.controls}'));

     });

    test('VLV using assertion control' ,(){
      var sortControl = new ServerSideSortRequestControl([new SortKey("sn")]);
      var vlvControl = new VLVRequestControl.assertionControl("Billard", 2, 3);
      var filter =  Filter.equals("objectclass", "inetOrgPerson");
      var result = ldap.search("dc=example, dc=com", filter, ["sn","cn","uid","mail"], controls:[sortControl,vlvControl]);

      return result.stream.listen( (SearchEntry entry)
         =>  info('======== entry: $entry'),

           onDone: () => info('======== Controls: ${result.controls}'));

    });

    // todo: how to run final method?
    //test('clean up', () => ldap.close());


  });

}
