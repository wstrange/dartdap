// This tests the example code found in the README file.
//
//----------------------------------------------------------------

import 'dart:async';

import 'package:dartdap/dartdap.dart';

Future example() async {

  // Create an LDAP connection object

  var host = "localhost";
  var ssl = false; // true = use LDAPS (i.e. LDAP over SSL/TLS)
  var port = 10389; // null = use standard LDAP/LDAPS port
  var bindDN = "cn=Manager,dc=example,dc=com"; // null=unauthenticated
  var password = "p@ssw0rd";

  var connection = new LdapConnection(host: host);
  connection.setProtocol(ssl, port);
  await connection.setAuthentication(bindDN, password);

  try {
    // Perform search operation

    var base = "dc=example,dc=com";
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
        for (var value in attr.values) { // attr.values is a Set
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

main() async {
  await example();
}
