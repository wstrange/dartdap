import 'dart:async';

import 'package:dartdap/dartdap.dart';
import 'package:logging/logging.dart';

Future<void> main() async {
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}: ${r.loggerName}: ${r.level.name}: ${r.message}');
  });

  Logger.root.level = Level.FINE;

  await example();
}

var base = 'dc=example,dc=com';
var filter = Filter.present('objectClass');
var attrs = ['dn', 'objectclass'];

Future example() async {
  var host = 'localhost';
  var bindDN = 'uid=admin';
  var password = 'password';

  var connection = LdapConnection(
      host: host, ssl: false, port: 1389, bindDN: bindDN, password: password);

  try {
    await connection.open();
    // Perform search operation
    await connection.bind();
    print('Bind OK');

    print('******* before search');

    await _doSearch(connection);

    print('******* after search');
  } catch (e, stacktrace) {
    print('********* Exception: $e $stacktrace');
  } finally {
    // Close the connection when finished with it
    print('Closing');
    await connection.close();
  }
}

Future<void> _doSearch(LdapConnection connection) async {
  var searchResult = await connection.search(base, filter, attrs, sizeLimit: 5);
  print('Search returned ${searchResult.stream}');

  await for (var entry in searchResult.stream) {
    // Processing stream of SearchEntry
    print('dn: ${entry.dn}');

    // Getting all attributes returned

    for (var attr in entry.attributes.values) {
      for (var value in attr.values) {
        // attr.values is a Set
        print('  ${attr.name}: $value');
      }
    }
  }
}
