import 'package:unittest/unittest.dart';
import 'package:dartdap/ldap_client.dart';


main() {
  //var dn = "cn=test";
  var dn = "cn=Directory Manager";
  var pw = "Oracle123";
  LDAPConnection ldap;
  LDAPConnection ldaps;
  var ldapConfig = new LDAPConfiguration('test/ldap.yaml');
  var ldapsConfig = new LDAPConfiguration('test/ldap.yaml','ssl');

  initLogging();

  group('LDAP Bind Group', () {

    setUp( () {
      return ldapConfig.getConnection(false)
          .then( (c) => ldap = c);
    });

    tearDown( () {
      print("Teardown");
      //ldap.close(true);
    });

    test('Simple Bind using default connection creds', () {
      ldap.bind()
        .then( expectAsync1((LDAPResult r) {
            print("****** Got expected LDAP result $r");
            expect(r.resultCode, equals(0));
        }));
    });

    test('Bind to a bad DN', () {
      ldap.bind("cn=foofoo",pw)
        .then( expectAsync1((r) {
            expect(false,"Should not be reached");
        },count:0))
        .catchError( expectAsync1( (e) {
          print("Got expected async error ${e}");
          expect(e.resultCode,equals(ResultCode.INVALID_CREDENTIALS));
        }));
    });

    test('SSL Connect test', () {
      ldapsConfig.getConnection().then(
          expectAsync1((result) =>print('Connected via SSL OK')));
    });

  }); // end group


}
