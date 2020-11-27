import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import 'util.dart' as util;

Future<void> main()  async{
  final config = util.Config();

  group('Pool tests over LDAPS', () {
    runTests(config.directory(util.ldapsDirectoryName));
  }, skip: config.skipIfMissingDirectory(util.ldapsDirectoryName));

}

// TODO: Implement connection pool tests!!!

void runTests(util.ConfigDirectory configDirectory) {
  late LdapConnection ldap;
  late DN testPersonDN;
  late LdapConnectionPool pool;

  //----------------

  setUp(() async {
    ldap = configDirectory.getConnection();
    pool = LdapConnectionPool(ldap);

    // await purgeEntries(ldap, testPersonDN, branchDN);
    // Nothing to populate, since these tests exercise the 'add' operation
  });

  //----------------

  tearDown(() async {
    // await purgeEntries(ldap, testPersonDN, branchDN);
    await pool.close();
  });

  test('pool bind', () async {
    var r = await pool.bind();
    expect(r.resultCode, equals(ResultCode.OK));
  });

  test('simple crud', () async {

  });

}

