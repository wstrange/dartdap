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

## Using dartdap

### Overview

To perform operations on an LDAP directory, the basic process is:

1. Create an [LDAPConnection] object.
2. Connect to the LDAP directory (using the `connect` method).
3. Authenticate to the LDAP directory, if needed (using the `bind` method).
4. Perform LDAP operations (e.g. `search`, `add`, `delete` methods).
5. Close the connection (using the `close` method).

Please reference dartdap in _pubspec.yaml_
using `dartdap: "^0.1.0"` so
[pub versioning](https://www.dartlang.org/tools/pub/versioning.html)
will prevents breaking changes from being used. See the bottom of this page
for some notes about recent breaking changes.

### Basic example

```dart
import 'package:dartdap/dartdap.dart';

...

// Step 1: create an LDAP connection object

var host = "localhost";
var port = 10389; // null = use default LDAP/LDAPS port
var ssl = false;
var bindDN = "cn=Manager,dc=example,dc=com"; // null = unauthenticated bind
var password = "p@ssw0rd";

var connection = new LDAPConnection(host, port, ssl, bindDN, password);

try {
  // Step 2: connect to the LDAP directory

  await connection.connect();

  // Step 3: authenticate to the LDAP directory

  await connection.bind();

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
    for (var attr in entry.attributes.values) { // entry.attributes is a Map<String,Attribute>
      for (var value in attr.values) { // attr.values is a Set
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
  connection.close();
}
```

#### Step 1: create an LDAP connection object

The first step is to instantiate an [LDAPConnection] object using its
constructor. If the `port` is null, the default port is used based on
whether `ssl` is true or not (port 389 when SSL is not used, port 636
when SSL is used).

The binding parameters (`bindDN` and `password`) are optional.

#### Step 2: connect to the LDAP directory

The `connect` method is called to establish a network connection to
the LDAP directory. It uses the host, port and ssl properties of the
object. It returns a future which completes when the connection has
been established. If the connection cannot be established an exception
will be thrown: either [LdapSocketServerNotFoundException] or
[LdapSocketRefusedException].

#### Step 3: authenticate to the LDAP directory (optional)

Call the `bind` method to establish an authenticated bind.

The credentials (bindDN and password) can be provided as parameters to
the `bind` method. If they are not provided, the default credentials
in the object (e.g. set via its constructor) will be used.

If the bind fails, an exception will be thrown.

#### Step 4: perform search operation

This example performs a search operation.

The `search` method returns a [SearchResult] object, from which a
_stream_ of [SearchEntry] objects can be obtained. The results are
obtained by listening to the stream (which in the example is done
using the "await for" syntax).

The [SearchEntry] contains the entry's distinguished name and the
attributes returned.
The `dn` is a String. The `attributes` is a [Map] from the name of 
the attribute (a String) to an [Attribute].

An [Attribute] has a `values` member, which returns a [Set] of the
values of the attribute. It is a Set because LDAP allows attributes to
have multiple values.  It also has a `name` member, which is the name
of the attribute as a String.


#### Step 5: close the connection

When finished with the connection, call the `close` method.

In the above example, the close is performed in the _finally_ section,
to ensure it gets closed even if an exception is thrown.

### Adding entries

```dart
try {
  var attrs = {
    "objectClass": ["organizationalUnit"],
    "description": "Example organizationalUnit entry"
  };

  await ldap.add("ou=Engineering,dc=example,dc=com", attrs);

} on LdapResultEntryAlreadyExistsException catch (_) {
  // cannot add entry because it already exists

} on LdapException catch (e) {
  // some other problem
  
}
```

### Modifying entries

```dart
try {
  var mod1 = new Modification.replace("description", ["Engineering department"]);
  await ldap.modify("ou=Engineering,dc=example,dc=com", [mod1]);

} on LdapResultObjectClassViolationException catch (_) {
  // cannot modify entry because it would violate the schema rules

} on LdapException catch (e) {

}
```

### Moving entries

```dart
try {
  await ldap.modifyDN(oldDN, newDN);

} on LdapException catch (e) {

}
```

### Comparing entries

```dart
try {
  r = await ldap.compare("ou=Engineering,dc=example,dc=com", "description", "ENGINEERING DEPARTMENT");
  if (r.resultCode == ResultCode.COMPARE_FALSE) {
  
  } else if (r.resultCode == ResultCode.COMPARE_TRUE) {
  
  } else {
    assert(false);
  }

} on LdapException catch (e) {

}
```

### Deleting entries

```dart
try {
  await ldap.delete("ou=Business Development,dc=example,dc=com");

} on LdapResultNoSuchObjectException catch (_) {
  // entry did not exist to delete

} on LdapException catch (e) {

}
```

## Older example

This is an example of using dartdap without using the new
_await/async_ Dart syntax.

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

## Exceptions

Methods in the package throws exceptions which are subclasses
of the [LdapException] abstract class.

See the documentation for [LdapException] class for more details.

## Breaking changes

### Planned changes for future releases

- Renaming of other classes and methods to follow the Dart
  [conventions](https://www.dartlang.org/effective-dart/style/).
  For example, LDAPConnection and LDAPResult to become
  LdapConnection and LdapResult, respectively.

- LDAPConnection to be deprecated. Programs should use whatever
  configuration mechanism they normally use (e.g. databases or
  configuration files) rather than having to use a special
  configuration mechanism only for dartdap (and still having
  to use the other configuration mechanism for the rest of the
  program).

- Considering deprecating the [DN] since it offers limited value
  (syntax is not any more readable than using normal String operations)

### v0.0.9 to v0.1.0

- Library is now called "dartdap" instead of "ldap_client".  There was
  a disconnect: package X was imported, but only library Y was
  imported. That would have been ok if there were multiple libraries
  in dartdap (or plans to produce a LDAP server library), but it
  currently only contains one publically visible library.

- Internal organisation of libraries/imports/exports have been
  cleaned up. This should not be noticable by existing code,
  unless it was directly referencing those internal libraries
  or files.

- LDAPException renamed to LdapException to follow the Dart
  [conventions](https://www.dartlang.org/effective-dart/style/).

- New exceptions for all the LDAP result error conditions have been
  created and LDAP operations now throw them. Instead of checking the
  LDAPResult resultCode returned by the LDAP operations, catch the
  new exceptions.

- SocketException exceptions are now being internally caught and
  thrown in LdapSocketException objects. This make it easier to detect
  common failure conditions. Instead of catching SocketException,
  catch the new LdapSocketException (or its subclasses).
