import 'package:unittest/unittest.dart';
import 'package:dartdap/dartdap.dart';


main() {

  LDAPConnection ldap;
  var ldapConfig = new LDAPConfiguration('ldap.yaml');
  var ldapsConfig = new LDAPConfiguration('ldap.yaml','ssl-example');

  initLogging();

  group('LDAP Bind Group', () {

    setUp( () {
      return ldapConfig.getConnection(false)
          .then( (c) => ldap = c);
    });

    tearDown( () {
      logMessage("Teardown");
      return ldapConfig.close();
    });

    test('Simple Bind using default connection creds', () {
      ldap.bind()
          .then( expectAsync1((LDAPResult r) {
            logMessage("****** Got expected LDAP result $r");
            expect(r.resultCode, equals(0));
        }));
    });

    test('Bind to a bad DN', () {
      ldap.bind(bindDN:"cn=foofoo",password:"password")
        .then( expectAsync1((r) {
            expect(false,"Should not be reached");
        },count:0))
        .catchError( expectAsync1( (e) {
          logMessage("Got expected error ${e}");
          expect(e.resultCode,equals(ResultCode.INVALID_CREDENTIALS));
        }));
    });

    test('SSL Connect test', () {
      ldapsConfig.getConnection().then(
          expectAsync1((result) =>logMessage('Connected via SSL OK')));
    });

  }); // end group


  test('clean up', () => ldapsConfig.close() );


}
