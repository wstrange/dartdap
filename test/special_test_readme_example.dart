// This tests the example code found in the README file.
//
//----------------------------------------------------------------

import 'dart:async';

import 'package:dartdap/dartdap.dart';
import 'package:test/test.dart';

import 'config.dart' as util;

Future<void> example(String host, int port, bool ssl, String bindDN,
    String password, DN testDN) async {
  // Create connection

  var connection = LdapConnection(
      host: host, ssl: ssl, port: port, bindDN: bindDN, password: password);

  await connection.open();
  await connection.bind();

  try {
    // Perform search operation

    var base = testDN.dn;
    var filter = Filter.present('objectClass');
    var attrs = ['dc', 'objectClass'];

    var count = 0;

    var searchResult = await connection.search(base, filter, attrs);
    await for (var entry in searchResult.stream) {
      // Processing stream of SearchEntry
      count++;
      print('dn: ${entry.dn}');

      // Getting all attributes returned

      for (var attr in entry.attributes.values) {
        for (var value in attr.values) {
          print('  ${attr.name}: $value');
        }
      }

      // Getting a particular attribute
      var dc = entry.attributes['dc'];
      if (dc == null) {
        print('Missing expected attribute dc!');
      } else {
        assert(dc.values.length == 1);
        var dcf = dc.values.first;
        print('# dcf=$dcf');
      }
    }

    print('# Number of entries: $count');
  } catch (e) {
    print('Exception: $e');
  } finally {
    // Close the connection when finished with it
    await connection.close();
  }
}

void main() async {
  final config = util.Config();

  group('tests', () async {
    final d = config.defaultDirectory;
    await example(d.host, d.port, d.ssl, d.bindDN, d.password, d.testDN);
  }, skip: config.skipIfMissingDefaultDirectory);
}
