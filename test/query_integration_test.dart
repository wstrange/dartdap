import "package:test/test.dart";
import "util.dart" as util;
import "package:dartdap/dartdap.dart";

// Integration test against OpenDJ, populated with 2000 sample users under dc=example,dc=com
// TODO: Refactor test suites to better accommodate AD, OpenDJ, OpenLDAP, etc.

/// Name of the directory configuration to use.
///
/// This is a special test that does not work with the default test directory.
/// It requires a directory that has been pre-populated with sample users.
///
/// This test should work with ANY LDAP DIRECTORY that has the 2000 sample users
/// under the "baseDN". The directory implementation does not matter. What
/// matters is the contents of the directory. Hence, the name of the directory
/// should not describe the implementation of the directory (i.e. not "opendj"),
/// but describes the contents or behaviour of the directory.

const specialDirectoryName = 'populated-with-2000-users';

void main() {
  final config = util.Config();

  test("Query Search test", () async {
    final dirConfig = config.directory(specialDirectoryName);
    final ldap = dirConfig.connect();

    var results = await ldap.query(dirConfig.baseDN,
        '(uid=user*21*)', ['dn', 'email'],
        scope: SearchScope.SUB_LEVEL);

    await results.stream.forEach((r) => print("R = $r"));

    await ldap.close();
  }, skip: config.skipIfMissingDirectory(specialDirectoryName));

  // TODO: modify test so it creates the 2000 people entries before the query.
  // That way it can work with any default test directory.
}
