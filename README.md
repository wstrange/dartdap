# An LDAP Client Library for Dart

This library allows LDAP v3 clients to be implemented.

The Lightweight Directory Access Protocol (LDAP) is a protocol for
accessing directories. These directories are organised as a hierarchy
(or tree) of entries. Each entry contains a set of attribute and
values. Each entry can be identified by a _distinguished name_, which
is a sequence of attribute/value pairs.  The LDAP protocol can be used
to query, as well as modify, these directories.

This library supports the LDAP v3 protocol, which is defined in
IETF [RFC 4511](http://tools.ietf.org/html/rfc4511).

The operations supported by this implementation include: BIND, ADD,
MODIFY, DEL, MODIFYDN, SEARCH and COMPARE.

## Examples

### Search

Create an LDAP connection and perform a simple search using it.

```dart
var ldap_settings = {
  "default": {
    "host": "10.211.55.35",
    "port": 389,
    "bindDN": "cn=admin,dc=example,dc=com",
    "password": "p@ssw0rd",
    "ssl": false
  }
};

var ldapConfig = new LDAPConfiguration.fromMap(ldap_settings);

ldapConfig.getConnection().then((LDAPConnection ldap) {
  var attrs = ["dn", "cn", "objectClass"];
  var filter = Filter.present("objectClass");

  ldap.search("dc=example,dc=com", filter, attrs).stream
      .listen((SearchEntry entry) => print("Found $entry"));
});
```

### Other examples

See the integration test for more examples.

## TODO

* Documentation. For now please see integration_test.dart for sample usage
* Improve conciseness / usability of API
* Paged search
* VLV Search. See [https://tools.ietf.org/html/draft-ietf-ldapext-ldapv3-vlv-09]
* An LDIF parser would be nice for creating integration test data
* Do we need to implement flow control so the client does not overwhelm
 the server?



