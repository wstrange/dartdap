# An LDAP Client Library for Dart

This library is used to implement LDAP v3 clients.

The Lightweight Directory Access Protocol (LDAP) is a protocol for
accessing directories. These directories are organised as a hierarchy
of _entries_, where one or more root entries are allowed. Each entry
contains a set of attribute and values. Each entry can be identified
by a _distinguished name_, which is a sequence of attribute/value
pairs.  The LDAP protocol can be used to query, as well as modify,
these directories.

This library supports the LDAP v3 protocol, which is defined in
IETF [RFC 4511](http://tools.ietf.org/html/rfc4511).

The LDAP operations supported by this implementation include: bind, add,
modify, delete, modify, search and compare.

## Examples

Create an LDAP connection and perform a simple search using it.

This example first creates an LDAPConfiguration object with the
settings for connecting to the LDAP server.  It then gets the
LDAPConnection object using those settings (i.e. performs an LDAP bind
operation). With the connection, it performs an LDAP search operation.
The search operation produces a stream of SearchResult objects: in
this example, the entries are each printed out along with a total
count at the end.

To perform an anonymous bind, leave out the bindDN and password.

```dart
import 'package:dartdap/dartdap.dart';

void main() {
  var ldapConfig = new LDAPConfiguration("ldap.example.com",
                                         ssl: false, 
                                         bindDN: "cn=admin,dc=example,dc=com",
                                         password: "p@ssw0rd");

  ldapConfig.getConnection().then((LDAPConnection ldap) {
    var base = "dc=example,dc=com";
    var filter = Filter.present("objectClass");
    var attrs = ["dn", "cn", "objectClass"];

    print("LDAP Search: baseDN=\"${base}\", attributes=${attrs}");

    var count = 0;

    ldap.search(base, filter, attrs).stream.listen(
        (SearchEntry entry) => print("${++count}: $entry"),
        onDone: () => print("Found ${count} entries"));
  });
}
```

See the integration test for more examples.

## TODO

* Documentation. For now please see integration_test.dart for sample usage
* Improve conciseness / usability of API
* Paged search
* VLV Search. See [https://tools.ietf.org/html/draft-ietf-ldapext-ldapv3-vlv-09]
* An LDIF parser would be nice for creating integration test data
* Do we need to implement flow control so the client does not overwhelm
  the server?

