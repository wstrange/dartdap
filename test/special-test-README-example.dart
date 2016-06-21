// This tests the example code found in the README file.
//
//----------------------------------------------------------------

import 'dart:async';
import 'package:test/test.dart';

import 'package:dartdap/dartdap.dart';

Future example() async {
  var host = "localhost";
  var port = 10389; // null = use default LDAP/LDAPS port
  var ssl = false;
  var bindDN = "cn=Manager,dc=example,dc=com"; // null = unauthenticated bind
  var password = "p@ssw0rd";

  var connection = new LDAPConnection(host, ssl: ssl, port: port);

  try {
    // Step 2: connect to the LDAP directory

    await connection.connect();

    // Step 3: authenticate to the LDAP directory

    await connection.bind(bindDN, password);

    // Step 4: perform search operation

    var base = "dc=example,dc=com";
    var filter = Filter.present("objectClass");
    var attrs = ["dc", "objectClass"];

    var count = 0;

    await for (var entry in connection.search(base, filter, attrs).stream) {
      // Processing stream of SearchEntry
      count++;
      print("dn: ${entry.dn}");

      // Getting all attributes returned
      for (var attr in entry.attributes.values) {
        // entry.attributes is a Map<String,Attribute>
        for (var value in attr.values) {
          // attr.values is a Set
          print("  ${attr.name}: $value");
        }
      }

      // Getting a particular attribute
      assert(entry.attributes["dc"].values.length == 1); // expecting one value
      var dc = entry.attributes["dc"].values.first;
      print("# dc=$dc");
    }

    print("# Number of entries: ${count}");
  } catch (e) {
    print("Exception: $e");
  } finally {
    // Step 5: close the connection
    await connection.close();
  }
}

main() async {
  await example();
}
