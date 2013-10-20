An LDAP Client Library for Dart

Implements the LDAP v3 protocol. This library depends on the ASN1 parser library .


Implemented operations include BIND, ADD, MODIFY, DEL, MODIFYDN, SEARCH, COMPARE

Example:
```dart
var ldapConfig = new LDAPConfiguration("ldap.yaml");
var attrs = ["dn", "cn", "objectClass"];
var filter = Filter.substring("cn=A*");

ldapConfig.getConnection().then( (LDAPConnection ldap) {
	ldap.search("dc=example,dc=com", filter, attrs).
		listen( (SearchEntry entry) => print('Found $entry'));
});
```

See the integration test for more examples

TODO List:

* Documentation. For now please see integration_test.dart for sample usage
* Improve conciseness / usability of API
* Paged search
* VLV Search
* An LDIF parser would be nice for creating integration test data
* Do we need to implement flow control so the client does not overwhelm
 the server?



Design Issues

The library is asynchronous and there isn't a convenient way to throttle batch operations.
For example, if you  want to create 10,000 entries, a simple for loop will
create 10,000 in memory requests - which is probably not what you want. This
seems to be a general Dart async issue right now.

