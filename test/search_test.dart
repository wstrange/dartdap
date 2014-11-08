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

main() async {
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
      await ldap.close();
    });

    test('VLV Search', () {

      var slist = [new SortKey("uid")];

      var sortControl = new ServerSideSortRequestControl(slist);
      var vlvControl = new VLVRequestControl.offsetControl(200, 20, 10, 10, null);


      var filter = Filter.substring("cn=A*");
      var s = ldap.search("dc=example, dc=com", filter, ["sn","cn","uid","mail"], controls:[sortControl,vlvControl]);

      return s.listen( (SearchEntry entry) {
        // expected.
        info("Found ${entry}");
       });

    });


  });

}
