import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import 'setup.dart';

void main() async {
  late LdapConnection ldap;

  final testCN = 'téstè  (testy)';
  // final testCN = '(testy)';
  // final testCN = 'foo';

  final testRDN = RDN('cn', testCN);
  final testDN = DN.fromRDNs([testRDN, ...peopleDN.rdns]);

  setUpAll(() async {
    ldap = defaultConnection(ssl: true);
    await ldap.open();
    await ldap.bind();
  });

  setUp(() async {
    try {
      await setupBaseEntries(ldap);
    } catch (e, stack) {
      // ignore
      print('Ignored  Exception: $e, stackTrace: $stack');
    }

    await debugSearch(ldap);
  });

  tearDown(() async {
    await deleteIfExists(ldap, testDN);
  });

  test('Create user with non ascii chars', () async {
    print('creating $testDN');

    var r = await ldap.add(testDN, {
      'objectClass': ['inetOrgPerson'],
      'cn': testCN,
      'sn': 'testy tester',
      'userPassword': 'password',
    });
    expect(r.resultCode, equals(ResultCode.OK));

    print(r.diagnosticMessage);
    // now searach by DN
    var x = await ldap.query(testDN, '(objectClass=*)', ['cn', 'dn'], scope: SearchScope.BASE_LEVEL);

    var result = await x.getLdapResult();
    expect(result.resultCode, equals(ResultCode.OK));
    print('Result: $result');
  });
}
