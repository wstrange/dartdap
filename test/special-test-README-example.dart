// This tests the example code found in the README file.
//
//----------------------------------------------------------------

import 'dart:async';

import 'package:dartdap/dartdap.dart';
import 'package:test/test.dart';

import 'util.dart' as util;

Future<void> example(String host, int port, bool ssl, String bindDN,
    String password, DN testDN) async {
  // Create connection

  var connection = LdapConnection(host: host);
  connection.setProtocol(ssl, port);
  await connection.setAuthentication(bindDN, password);

  try {
    // Perform search operation

    var base = testDN.dn;
    var filter = Filter.present("objectClass");
    var attrs = ["dc", "objectClass"];

    var count = 0;

    var searchResult = await connection.search(base, filter, attrs);
    await for (var entry in searchResult.stream) {
      // Processing stream of SearchEntry
      count++;
      print("dn: ${entry.dn}");

      // Getting all attributes returned

      for (var attr in entry.attributes.values) {
        for (var value in attr.values) {
          // attr.values is a Set
          print("  ${attr.name}: $value");
        }
      }

      // Getting a particular attribute

      assert(entry.attributes["dc"].values.length == 1);
      var dc = entry.attributes["dc"].values.first;
      print("# dc=$dc");
    }

    print("# Number of entries: ${count}");
  } catch (e) {
    print("Exception: $e");
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
