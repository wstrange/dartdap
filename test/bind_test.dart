import 'package:unittest/unittest.dart';
import 'package:dartdap/dartdap.dart';

main()  {

  LDAPConnection ldap;
  var ldapConfig = new LDAPConfiguration('ldap.yaml');
  var ldapsConfig = new LDAPConfiguration('ldap.yaml','ssl-example');

  initLogging();

  group('LDAP Bind Group', () {

    setUp( () async {
      ldap = await ldapConfig.getConnection(false);
    });

    tearDown( () {
      logMessage("Teardown");
      return ldapConfig.close();
    });

    test('Simple Bind using default connection creds', () async {
      var result = await ldap.bind();
      expect(result.resultCode, equals(0));
    });

    test('Bind using a good DN', () async {
       return ldap.bind("cn=Directory Manager","password").then( (c){
        print("got result $c ${c.runtimeType}");
      } );

    });


    test('Bind using a good DN using async', () async {
      try {
        var r = await ldap.bind("cn=Directory Manager","password");
       expect(r.resultCode,equals(0));
      }
      catch(e) {
        fail("unexpected exception $e");
      }
    });

    test('Bind to a bad DN', () async {
      try {
        await ldap.bind("cn=foofoo","password");
        fail("Should not be able to bind to a bad DN");
      }
      catch(e) {
       expect(e.resultCode,equals(ResultCode.INVALID_CREDENTIALS));
      }
    });

    test('SSL Connect test', () async {
      try {
        var connection = await ldapsConfig.getConnection();
      }
      catch(e) {
        fail("Could not create SSL connection. Error = $e");
      }

    });

  }); // end group


  test('clean up', () => ldapsConfig.close() );


}
