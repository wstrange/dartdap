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

var base = DN('dc=example,dc=com');
var filter = Filter.present('objectClass');
var attrs = ['dn', 'objectclass'];

Future example() async {
  var host = 'localhost';
  var bindDN = DN('uid=admin');
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

    // Example of using healthCheck
    await _performHealthCheck(connection);

  } catch (e, stacktrace) {
    print('********* Exception: $e $stacktrace');
  } finally {
    // Close the connection when finished with it
    print('Closing');
    await connection.close();
  }
}

// Demonstrates the healthCheck function
Future<void> _performHealthCheck(LdapConnection connection) async {
  print('\n******* Performing Health Check *******');
  // At this point, the connection should be open and bound (from the main example function)
  // So, healthCheck should return true.
  bool isHealthy = await connection.healthCheck();
  print('Health check result (after bind): $isHealthy');

  // Example of health check on a connection that is open but not bound
  // We need a new connection for this, or to re-open the existing one without binding.
  // For simplicity, let's create a new connection instance.
  // Note: In a real application, you'd manage your connection instances carefully.
  var healthCheckConnection = LdapConnection(host: connection.host, port: connection.port, ssl: connection.isSSL);
  try {
    await healthCheckConnection.open();
    print('Opened a new connection for health check (not bound).');
    isHealthy = await healthCheckConnection.healthCheck();
    print('Health check result (open, not bound): $isHealthy');
  } catch (e, stacktrace) {
    print('Error during health check on not-bound connection: $e $stacktrace');
  } finally {
    await healthCheckConnection.close();
    print('Closed the dedicated health check connection.');
  }

  // Example of health check on a closed connection
  // The 'connection' instance from the main example will be closed in its finally block.
  // We can call healthCheck on it *after* it's closed, or create another one.
  // Let's use a new instance that we never open.
  var closedConnection = LdapConnection(host: connection.host, port: connection.port, ssl: connection.isSSL);
  isHealthy = await closedConnection.healthCheck();
  print('Health check result (unopened connection): $isHealthy');
  print('******* Finished Health Check *******');
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
