import 'dart:async';

import 'package:dartdap/dartdap.dart';
import 'package:logging/logging.dart';

final adminPassword = 'password';
final ou = DN('dc=example,dc=com');

/// A sample showing the use of the connection pool
///
Future<void> main() async {
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}: ${r.loggerName}: ${r.level.name}: ${r.message}');
  });

  Logger.root.level = Level.INFO;
  await example();
}

Future<void> example() async {
  var filter = Filter.present('objectclass');

  // Create a prototype connection
  var connection = LdapConnection(
      port: 1636,
      bindDN: DN('uid=admin'),
      password: adminPassword,
      ssl: true,
      badCertificateHandler: (cert) => true);
  // The pool is created from the connection. The pool implements the Ldap Interface
  var pool = LdapConnectionPool(connection);

  try {
    var searchResult =
        await pool.search(ou, filter, ['dn', 'objectclass'], sizeLimit: 10);

    await printResults(searchResult);

    // repeat search - to see if bind happens again
    searchResult =
        await pool.search(ou, filter, ['dn', 'objectclass'], sizeLimit: 5);
    await printResults(searchResult);

    // Try search on a bad DN
    searchResult = await pool
        .search(DN('ou=FooXXX'), filter, ['dn', 'objectclass'], sizeLimit: 5);
    await printResults(searchResult);
  } catch (e) {
    print('Exception --->$e  ${e.runtimeType}');
  }
  await pool.destroy();
}

Future<void> printResults(SearchResult searchResult) async {
  var result = await searchResult.getLdapResult();
  print('got result = $result');
  if (result.resultCode == ResultCode.OK ||
      result.resultCode == ResultCode.SIZE_LIMIT_EXCEEDED) {
    print('ok');
    await searchResult.stream.forEach((entry) {
      print('got entry $entry');
    });
  } else {
    print('ldap error ${result.resultCode}');
  }
}
