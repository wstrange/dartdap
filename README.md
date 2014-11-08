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
* VLV Search. See [https://tools.ietf.org/html/draft-ietf-ldapext-ldapv3-vlv-09]
* An LDIF parser would be nice for creating integration test data
* Do we need to implement flow control so the client does not overwhelm
 the server?



