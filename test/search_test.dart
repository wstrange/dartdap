import 'package:unittest/unittest.dart';
import 'package:dartdap/dartdap.dart';
import 'package:dartdap/src/protocol/ldap_protocol.dart';
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
  var ldapConfig = new LDAPConfiguration("test/ldap.yaml","default");

  startQuickLogging();
  Logger.root.level = Level.FINEST;

  group('Search encoding', () {

    test('no controls', () {
      var m = new LDAPMessage(1,
                              new SearchRequest("dc=example,dc=com",
                                                Filter.equals("cn", "bar"),
                                                [], SearchScope.BASE_LEVEL, 0),
                              null);
      var b = m.toBytes();
      expect(b, equals([0x30, 0x34, 0x02, 0x01, 0x01, 0x63, 0x2F, 0x04, 0x11, 0x64, 0x63, 0x3D, 0x65, 0x78, 0x61, 0x6D, 0x70, 0x6C, 0x65, 0x2C, 0x64, 0x63, 0x3D, 0x63, 0x6F, 0x6D, 0x0A, 0x01, 0x00, 0x0A, 0x01, 0x00, 0x02, 0x01, 0x00, 0x02, 0x01, 0x00, 0x01, 0x01, 0x00, 0xA3, 0x09, 0x04, 0x02, 0x63, 0x6E, 0x04, 0x03, 0x62, 0x61, 0x72, 0x30, 0x00]));
    });

    test('one control', () {
      var c = new ServerSideSortRequestControl([new SortKey('cn')]);
      var m = new LDAPMessage(1,
                              new SearchRequest("dc=example,dc=com",
                                                Filter.equals("cn", "bar"),
                                                [], SearchScope.BASE_LEVEL, 0),
                              [c]);
      var b = m.toBytes();
      expect(b, equals([0x30, 0x5a, 0x02, 0x01, 0x01, 0x63, 0x2f, 0x04, 0x11, 0x64, 0x63, 0x3d, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65, 0x2c, 0x64, 0x63, 0x3d, 0x63, 0x6f, 0x6d, 0x0a, 0x01, 0x00, 0x0a, 0x01, 0x00, 0x02, 0x01, 0x00, 0x02, 0x01, 0x00, 0x01, 0x01, 0x00, 0xa3, 0x09, 0x04, 0x02, 0x63, 0x6e, 0x04, 0x03, 0x62, 0x61, 0x72, 0x30, 0x00, 0xa0, 0x24, 0x30, 0x22, 0x04, 0x16, 0x31, 0x2e, 0x32, 0x2e, 0x38, 0x34, 0x30, 0x2e, 0x31, 0x31, 0x33, 0x35, 0x35, 0x36, 0x2e, 0x31, 0x2e, 0x34, 0x2e, 0x34, 0x37, 0x33, 0x04, 0x08, 0x30, 0x06, 0x30, 0x04, 0x04, 0x02, 0x63, 0x6e]));
    });

    test('two controls', () {
      var c1 = new ServerSideSortRequestControl([new SortKey('cn')]);
      var c2 = new VLVRequestControl.assertionControl('example', 0, 19, critical: true);
      var m = new LDAPMessage(1,
                              new SearchRequest("dc=example,dc=com",
                                                Filter.equals("cn", "bar"),
                                                [], SearchScope.BASE_LEVEL, 0),
                              [c1, c2]);
      var b = m.toBytes();
      expect(b, equals([0x30, 0x81, 0x8b, 0x02, 0x01, 0x01, 0x63, 0x2f, 0x04, 0x11, 0x64, 0x63, 0x3d, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65, 0x2c, 0x64, 0x63, 0x3d, 0x63, 0x6f, 0x6d, 0x0a, 0x01, 0x00, 0x0a, 0x01, 0x00, 0x02, 0x01, 0x00, 0x02, 0x01, 0x00, 0x01, 0x01, 0x00, 0xa3, 0x09, 0x04, 0x02, 0x63, 0x6e, 0x04, 0x03, 0x62, 0x61, 0x72, 0x30, 0x00, 0xa0, 0x55, 0x30, 0x22, 0x04, 0x16, 0x31, 0x2e, 0x32, 0x2e, 0x38, 0x34, 0x30, 0x2e, 0x31, 0x31, 0x33, 0x35, 0x35, 0x36, 0x2e, 0x31, 0x2e, 0x34, 0x2e, 0x34, 0x37, 0x33, 0x04, 0x08, 0x30, 0x06, 0x30, 0x04, 0x04, 0x02, 0x63, 0x6e, 0x30, 0x2f, 0x04, 0x17, 0x32, 0x2e, 0x31, 0x36, 0x2e, 0x38, 0x34, 0x30, 0x2e, 0x31, 0x2e, 0x31, 0x31, 0x33, 0x37, 0x33, 0x30, 0x2e, 0x33, 0x2e, 0x34, 0x2e, 0x39, 0x01, 0x01, 0xff, 0x04, 0x11, 0x30, 0x0f, 0x02, 0x01, 0x00, 0x02, 0x01, 0x13, 0x81, 0x07, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65]));
    });

  });

  group('LDAP Search tests ', ()  {
    // create a connection. Return a future that completes when
    // the connection is available and bound
    setUp( ()  async {
     ldap = await ldapConfig.getConnection();
     info("Created ldap connection");
    });

    tearDown( () async {
      await ldap.close();
      //ldap.close();
      info("connection closed");
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

              onDone: expectAsync(() => info('======== Controls: ${result.controls}')));

     });

    test('VLV using assertion control' ,(){
      var sortControl = new ServerSideSortRequestControl([new SortKey("sn")]);
      var vlvControl = new VLVRequestControl.assertionControl("Billard", 2, 3);
      var filter =  Filter.equals("objectclass", "inetOrgPerson");
      var result = ldap.search("dc=example, dc=com", filter, ["sn","cn","uid","mail"], controls:[sortControl,vlvControl]);

      return result.stream.listen( (SearchEntry entry)
         =>  info('======== entry: $entry'),

           onDone: expectAsync(() => info('======== Controls: ${result.controls}')));

    });

    // todo: how to run final method?
    //test('clean up', () => ldap.close());


  });

}
