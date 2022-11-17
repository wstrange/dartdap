import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import 'util.dart' as util;

Future<void> main() async {
  final config = util.Config();

  group('Pool tests over LDAPS', () {
    runTests(config.directory(util.ldapsDirectoryName));
  }, skip: config.skipIfMissingDirectory(util.ldapsDirectoryName));
}

// Connection Pool tests
// Note that to test reconnection the server must be manually stopped/started

void runTests(util.ConfigDirectory configDirectory) {
  late LdapConnection ldap;
  late LdapConnectionPool pool;

  //----------------

  setUp(() async {
    ldap = configDirectory.getConnection();
    pool = LdapConnectionPool(ldap);

    await pool.bind();

    // await purgeEntries(ldap, testPersonDN, branchDN);
    // Nothing to populate, since these tests exercise the 'add' operation
  });

  //----------------

  tearDown(() async {
    // await purgeEntries(ldap, testPersonDN, branchDN);
    print('Tear down pool');
    await pool.close();
  });

  // Used for testing socket connections. For now, we manually terminate
  // the socket and see if this recovers.
  test('socket reconnection test', () async {
    for (var i = 0; i < 5; ++i) {
      try {
        var r = await pool.query(configDirectory.testDN.dn, '(objectclass=*)',
            ['objectclass', 'dn']);
        var ldapResult = await r.getLdapResult();
        var numResults = await r.stream.length;
        print('pass $i ldapResult = $ldapResult number results=$numResults\n');
        await Future.delayed(Duration(seconds: 5));
      } catch (e) {
        fail('Test failed with exception $e');
      }
    }
  }, timeout: Timeout(Duration(seconds: 400)));

  test('two connections test', () async {
    var c1 = await pool.getConnection(bind: true);
    var c2 = await pool.getConnection(bind: true);

    for (var i = 0; i < 5; ++i) {
      try {
        var r = await c1.query(configDirectory.testDN.dn, '(objectclass=*)',
            ['objectclass', 'dn']);
        var ldapResult = await r.getLdapResult();
        var numResults = await r.stream.length;
        print('c1 $i ldapResult = $ldapResult number results=$numResults\n');

        r = await c2.query(configDirectory.testDN.dn, '(objectclass=*)',
            ['objectclass', 'dn']);
        ldapResult = await r.getLdapResult();
        numResults = await r.stream.length;
        print('c2 $i ldapResult = $ldapResult number results=$numResults\n');

        await Future.delayed(Duration(seconds: 5));
      } catch (e) {
        fail('Test failed with exception $e');
      } finally {
        await pool.releaseConnection(c1);
        await pool.releaseConnection(c2);
      }
    }
  }, timeout: Timeout(Duration(seconds: 400)));
}
