import "package:test/test.dart";
import "util.dart" as util;
import "package:dartdap/dartdap.dart";

// Integration test against OpenDJ, populated with 2000 sample users under dc=example,dc=com

var baseDN = "ou=People,dc=example,dc=com";

main() {
  test("Query Search test", () async {
    var ldap = util.getConnection("test/Test-config.yaml", "test-LDAP");

    var results = await ldap.query(baseDN, "(uid=user*21*)", ["dn", "email"],
        scope: SearchScope.SUB_LEVEL);

    await results.stream.forEach((r) => print("R = $r"));


    await ldap.close();

  });
}




