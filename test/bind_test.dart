import 'package:unittest/unittest.dart';
import 'package:dartdap/ldap_client.dart';



main() {
  //var dn = "cn=test";
  var dn = "cn=Directory Manager";
  var pw = "Oracle123";
  LDAPConnection c;

  initLogging();

  group('LDAP Bind Group', () {

    setUp( () {
      print("Create new connection");
      c = new LDAPConnection('localhost',1389);
    });

    tearDown( () {
      print("Teardown");
      c.close(true);
    });

    test('Simple Bind', () {
      c.connect()
        .then( (r) => c.bind(dn,pw))
        .then( expectAsync1((LDAPResult r) {
            print("****** Got expected LDAP result $r");
            expect(r.resultCode, equals(0));
        }));
    });

    test('Bind to bad DN', () {
      print("BAD BIND test");
      c.connect()
        .then( (r) => c.bind("cn=foofoo",pw))
        .then( expectAsync1((r) {
            expect(false,"Should not be reached");
        },count:0))
        .catchError( expectAsync1( (e) {
          print("Got expected async error ${e}");
          expect(e.error.resultCode,equals(49));
        }));
    });

  }); // end group


}
