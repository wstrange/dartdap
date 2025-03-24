# An LDAP v3 Client Library for Dart

The Lightweight Directory Access Protocol (LDAP) is a protocol for
accessing directories.

An LDAP directory is organised as a hierarchy of _entries_, where one
or more root entries are allowed.  Each entry can be identified by a
_distinguished name_, which is an ordered sequence of attribute/value
pairs.  Each entry contains a set of _attributes_. Attributes have a
name and are associated with a set of one or more values
(i.e. attributes can be repeated and are unordered).

This library can be used to query (search for and compare entries) and
modify (add, delete and modify) LDAP directories.

This library supports the LDAP v3 protocol, which is defined in
IETF [RFC 4511](https://tools.ietf.org/html/rfc4511).

Breaking changes from previous versions are described at the
bottom of this page.

## Using dartdap

### Examples

To perform operations on an LDAP directory, the basic process is:

1. Create an LDAP connection (`LdapConnection`).
2. Perform LDAP operations (`search`, `add`, `modify`, `modifyDN`, `compare`, `delete`).
3. Close the connection (`close`).

The following [examples](example) are provided:

* [main.dart](example/main.dart) - A basic sample using the LdapConnection() class
* [pool.dart](example/pool.dart) - Connection pool example
* [paged_search.dart](example/paged_search.dart) - demonstrates how to use the paged search control

Note:  As of version 0.5.0, An experimental connection pool is also provided. Please read [pool.md](pool.md).

#### Create an LDAP connection

The first step is to instantiate an `LdapConnection` object using its
constructor.

These properties of the connection can be changed from their defaults:

* hostname (defaults to "localhost");
* ssl: false is plain LDAP, true is LDAPS (LDAP  over SSL/TLS) (defaults to false);
* port: port number (defaults to standard port for LDAP/LDAPS: 389 or 636);
* bindDN: distinguished name for binding, null means unauthenticated (default is null);
* password: password for binding.

These properties can be set using named parameters to the constructor,
or with the `setProtocol` and `setAuthentication` methods.

#### Perform LDAP operations

This example performs a search operation.

The `search` method returns a Future to a `SearchResult` object, from
which a _stream_ of `SearchEntry` objects can be obtained. The results
are obtained by listening to the stream (which in the example is done
using the "await for" syntax).

The `SearchEntry` contains the entry's distinguished name and the
attributes returned.
The `dn` is a String. The `attributes` is a `Map` from the name of
the attribute (a String) to an `Attribute`.

An `Attribute` has a `values` member, which returns a `Set` of the
values of the attribute. It is a Set because LDAP allows attributes to
have multiple values.  It also has a `name` member, which is the name
of the attribute as a String.

#### Close the connection

When finished with the connection, call the `close` method.

In the above example, the close is performed in the _finally_ section,
to ensure it gets closed even if an exception is thrown.

The close method returns a Future, which completes when the
connection is completely closed.

### Searching

A search request returns a stream of SearchResults.

There is _EXPERIMENTAL_ support for search result references (referrals)

If SearchResult.referrals[] is not empty, it is an array of strings which are the DNs to repeat
the search request. The SDK does not automatically follow referrals.

There are two search methods:

* `ldap.search` takes a dart `Filter` object. This is the preferred method. See note below.
* `ldap.query` takes an <https://tools.ietf.org/html/rfc2254> string to construct the filter

### Adding entries

```dart
try {
  var attrs = {
    "objectClass": ["organizationalUnit"],
    "description": "Example organizationalUnit entry"
  };

  await ldap.add(DN("ou=Engineering,dc=example,dc=com"), attrs);

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
  await ldap.modify(DN("ou=Engineering,dc=example,dc=com"), [mod1]);

} on LdapResultObjectClassViolationException catch (_) {
  // cannot modify entry because it would violate the schema rules

} on LdapException catch (e) {
  // some other problem
}
```

### Moving entries

```dart
try {
  await ldap.modifyDN(oldDN, newDN);

} on LdapException catch (e) {
  // some other problem
}
```

### Comparing entries

```dart
try {
  r = await ldap.compare(DN("ou=Engineering,dc=example,dc=com"),
                         "description", "Engineering Dept");
  if (r.resultCode == ResultCode.COMPARE_FALSE) {

  } else if (r.resultCode == ResultCode.COMPARE_TRUE) {

  } else {
    assert(false);
  }

} on LdapException catch (e) {
  // some other problem
}
```

### Deleting entries

```dart
try {
  await ldap.delete(DN("ou=Business Development,dc=example,dc=com"));

} on LdapResultNoSuchObjectException catch (_) {
  // entry did not exist to delete

} on LdapException catch (e) {
  // some other problem
}
```

## Connecting and authenticating

The `LdapConnection` provides a basic connection to the LdapServer. The caller is
responsible for performing any Bind() operations, handling any disconnects, or
retrying on failure.

As of 0.5.0, a protoype LdapConnectionPool() is provided that handles some of the
these tasks. The pool implements the Ldap() interface, and will attempt to bind()
with the provided credentials, and will retry a connection if the server is not
available.

The Connection pool is still experimental, and provides only basic functionality.

See the documentation of `LdapConnection` and `LdapConnectionPool` for more details.

## Exceptions

Methods in the package throws exceptions which are subclasses
of the `LdapException` abstract class.

See the documentaiton of `LdapException` for more details.

## Logging

This package uses the Dart
[logging](https://pub.dartlang.org/packages/logging) package for
logging.

The logging is mainly useful for debugging the package.

### Loggers

The following loggers are used:

Logger: `ldap.control`

* finest = parsing of controls

Logger: `ldap.session`

* warnings = certificate issues
* fine = connections successfully established, and closing them
* finer = details about attempts to establish a connection

Logger: `ldap.send.ldap` for the LDAP messages sent.

* fine = LDAP messages sent.
* finest = details of LDAP message construction

Logger: `ldap.send.bytes` for the raw bytes sent to the socket.
Probably only useful when debugging the dartdap package.

* severe = errors/exceptions when sending
* fine = number of raw bytes sent

Logger: `ldap.recv.ldap` for the LDAP messages receive
(i.e. received ASN.1 objects processed as LDAP messages).

* fine = LDAP messages received.
* finer = LDAP messages processing.

Logger: `ldap.recv.asn1` for the ASN.1 objects received (i.e. parsed
from the raw bytes received). Probably only useful when debugging the
dartdap package.

* fine = ASN.1 messages successfully parsed from the raw bytes
* finest = shows the actual bytes making up the value of the ASN.1 message

Logger: `ldap.recv.bytes` for the raw bytes received from the
  socket.  Probably only useful when debugging the dartdap package.

* fine = number of raw bytes read
* finer = parsing activity of converting the bytes into ASN.1 objects
* finest = shows the actual bytes received and the number in the buffer to parse

### Logging Examples

To take advantage of the hierarchy of loggers, enable
`hierarchicalLoggingEnabled` and set the logging level on individual
loggers. If the logging level is not explicitly set on a logger,
it is inherited from its parent. The root logger is the ultimate
parent; and its logging level is initally Level.INFO.

For example, to view high level connection and LDAP messages send/received:

```dart
import 'package:logging/logging.dart';

...

Logger.root.onRecord.listen((LogRecord rec) {
  print('${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec.message}');
});

hierarchicalLoggingEnabled = true;

new Logger("ldap.session").level = Level.FINE;
new Logger("ldap.send.ldap").level = Level.FINE;
new Logger("ldap.recv.ldap").level = Level.FINE;
```

To debug messages received:

```dart
new Logger("ldap.recv.ldap").level = Level.ALL;
new Logger("ldap.recv.asn1").level = Level.FINER;
new Logger("ldap.recv.bytes").level = Level.FINE;
```

Note: in the above examples: SHOUT, SEVERE, WARNING and INFO will
still be logged (except for those loggers and their children where the
level has been set to Level.OFF). To disable those log messages
change the root logger from its default of Level.INFO to Level.OFF.

For example, to suppress all log messages (including suppressing
SHOUT, SEVERE, WARNING and INFO):

```dart
Logger.root.level = Level.OFF;
```

Or leave the root level at the default and only disable logging
from the package:

```dart
new Logger("ldap").level = Level.OFF;


## LDAP Filters and Directory Results.

You are strongly encouraged to use the `Filter` class and `ldap.search()` to construct LDAP filters programatically in preference to using `query` with filter strings.

For example:

```dart
  var filter = Filter.equals("cn", "John Doe");
  var filter = Filter.present("cn");
  var filter = Filter.approx("cn", "John Doe");
  var filter = Filter.greaterOrEquals("cn", "John Doe");
  var filter = Filter.lessOrEquals("cn", "John Doe");
  var filter = Filter.substring("cn", "John Doe");
  var filter = Filter.and([Filter.equals("cn", "John Doe"), Filter.equals("sn", "Doe")]);
  var filter = Filter.or([Filter.equals("cn", "John Doe"), Filter.equals("sn", "Doe")]);
  var filter = Filter.not(Filter.equals("cn", "John Doe"));

  // Avoid this. The parentheses will not be escaped properly.
  ldap.query(('member=cn=some user with (),dc=foo,dc=bar', ...));
```

If directory entries contains special characters such as parentheses, commas, *, etc. - you must properly escape them in string filters. This can be
tricky and often leads to bugs.  Using the Filter class will properly escape these characters (modulo any bugs).

If you get results back from the server that contain special characters, you should not convert them to strings unless you really need to. Instead, use the ASN1Object values directly
as the server has already properly escaped them. In addition to Strings, you can use DNs or ASN1OctetStrings as the assertion value in Filters. For example `Filter.equals('member', johnDN)`.

As a convenience, the ASN1 library will convert ASN1OctetStrings to a vanilla string when you call toString() on the object. This uses utf-8 decoding to convert the octet string which is what LDAP servers use.
Note that Dart uses utf-16 encoded strings internally.


```

## Breaking changes

### 0.11.0

There were several bugs related to handling of special characters in DNs and Attributes. Dart uses utf16 encoded strings, and
most ldap servers expect utf8 encoded strings. This can cause problems when special characters are used in DNs and Attributes.

To address this, the handling of DNs and RDNs has been improved. These are now proper Dart classes that handle escaping, concatenation and parsing.

An `RDN` class has been added to represent relative distinguished names.

RDNs will handle escaping and unescaping of special characters for use in DNs.

RDNs can be constructed as follows:

```dart
// From a String
var rdn = RDN.fromString("ou=Engineering");
// From name and value
var rdn = RDN("ou", "Engineering");
// From an OctetString. This is useful when the RDN is received from an LDAP server
var rdn = RDN.fromOctetString("ou", ASN1OctetString("Engineering"));
```

A DN can be constructed as follows:

```dart
// From a String that will be parsed
var dn = DN("ou=Engineering,dc=example,dc=com");
// From an OctetString. This is useful when the DN is received from an LDAP server
var dn = DN.fromOctetString(OctetString.fromUtf8("ou=Engineering,dc=example,dc=com"));

// DN's can be concatenated together using the plus operator:
var dn1 = DN("dc=example,dc=com");
var dn2 = DN("ou=Engineering");
var dn = dn1 + dn2;

// RDNs can be concatenated to a DN
var dn = RDN("ou=Engineering") + DN("dc=example,dc=com") ;
```

#### Attribute handling

Previous versions attempted to returned search results as a `Map<String, Set>`, where the key is the attribute name, and the value is a set of values as Dart objects (mostly Strings).

This can lead to errors for things like a list of DNs returned from an LDAP server. As an example, if you query for role members, you will get a list of DNs as the value of the `member` attribute. Should you escape the String values when sent back to the server or not? The answer is no, the server has already escaped values.

To make this more transparent, `Attribute.values`  returned from search is a Set of ASN1Objects. In most cases these will be ASN1OctetStrings, but they could be other types of ASN1Objects.

If you are going to use the results of a search in another LDAP operation, you should not convert the values to Strings. Instead do something like this:

```dart
  // result is a SearchResult
  var memberAttr = result.attributes["member"];
  for (var attr in memberAttr) {
      // Do something with the octetString.
      // If sent back to the server this will be properly escaped
      var myDN = DN.fromOctetString(attr as ASN1OctetString);
    }
```
As a general rule retain the values as ASN1Objects until you really need them as Dart Objects.

Note that ASN1OctetString.toString() will return the utf8 decoded string. For convenience you can convert objects that you know are strings:

```dart
  var myString = '$someObjectThatYouKnowisAnOctetString';
```


### 0.9.0

Distinguished names (DNs) are now represented by the `DN` class instead of a String.
This allows for more rigourous checking of DNs, including escaping and unescaping of special characters.

The various ldap operations are now updated as follows:

```dart
# Old method
await ldap.add("ou=Engineering,dc=example,dc=com", attrs);
# New method
await ldap.add(DN("ou=Engineering,dc=example,dc=com"), attrs);

# Old method
await ldap.modify("ou=Engineering,dc=example,dc=com", [mod1]);
# New method
await ldap.modify(DN("ou=Engineering,dc=example,dc=com"), [mod1]);

... etc.

```

### 0.6.2

LdapConnectionPool has been refactored.

### 0.6.0

* The library user is now responsible for waiting for all LDAP operations to complete before
calling connection.close()

### 0.5.0

There are many breaking changes in 0.5.0. The most signifcant are:

* dartdap is now null safe.
* The `LdapConnection` class no longer handles automatic retry or error handling. A new
`LdapConnectionPool` has been introduced that will host this functionality.

See the [CHANGELOG.md](CHANGELOG.md)

### Version 0.4.0

* `LdapConnection.search` new signature is `search(attributeName,searchExpression)`
* A new `LdapConnection.query(attr,searchQuery)` supports rfc2254 query filters.

### Version 0.1.x to 0.2.x

* `LdapConnection` changed to support automatic
  connection/reconnections (and authentication when needed). This
  allows connections to be safely reused (i.e. kept open for later
  operations without having to re-open the connection). Previously,
  there was no guarantee a previously working connection would still
  be working when an LDAP operation was performed later: it could have
  been disconnected by intermittent network errors or LDAP server
  timeouts. Previously, the only safe way to use a connection was to
  open one for each LDAP operation (which is very inefficient) or to
  always expect LDAP operations could fail and to open a new
  connection if it fails (verbose and inelegant code).

* The `search` method returns a _Future_ to a `SearchResult`.
  Previously, it returned the SearchResult synchronously.  This change
  was necessary because (with the introduction of automatic
  connections) a search could cause the connection to be opened, and
  bind request to be sent, before the search request is actually sent.

* Renaming of other classes and methods to consistently follow the
  Dart naming
  [conventions](https://www.dartlang.org/effective-dart/style/).  For
  example, `LDAPConnection` becomes `LdapConnection`, `LDAPResult`
  becomes `LdapResult`, `LDAPUtil` becomes `LdapUtil`.

* Exception raised if a bad certificate is encountered when opening a
  SSL/TLS connection. Provide a bad certificate handler function, if
  the application wants to override the default behaviour. Other than
  for testing, accepting bad certificates is a security risk: so, the
  default behaviour is the safer option.

* Internal classes hidden from public interface
  (e.g. `ConnectionManager`, `LDAPUtil`).

* `LDAPConfiguration` removed.

### Version 0.0.x to 0.1.x

* Library is now called "dartdap" instead of "ldap_client".  There was
  a disconnect in the naming: package X was imported, but only library
  Y was imported. That would have been ok if it had multiple
  libraries, but it currently only contains one publicly visible
  library. Also, many of the classes could apply an LDAP server too.

* `LDAPException` renamed to `LdapException` to follow the Dart naming
  [conventions](https://www.dartlang.org/effective-dart/style/).

* New exception classed defined for all the LDAP result error
  conditions. All LDAP operations now throws these new
  exceptions. Instead of checking the resultCode in the LDAPResult
  returned by the LDAP operations, catch the new exceptions.

* `SocketException` exceptions are now being internally caught and
  thrown as `LdapSocketException` objects. This make it easier to detect
  common failure conditions. Instead of catching `SocketException`,
  catch the new `LdapSocketException` or one of its subclasses.

* `LDAPConfiguration` is deprecated. Programs should use whatever
  configuration mechanism they normally use (e.g. databases or
  configuration files) rather than having to use a special
  configuration mechanism only for dartdap (and still having
  to use the other configuration mechanism for the rest of the
  program). It is also unsafe due to a race condition that could
  occur if multiple connections are being established.

* Internal organisation of libraries/imports/exports have been
  cleaned up. This should not be noticable by existing code,
  unless it was directly referencing those internal libraries
  or files.

## References

<https://tools.ietf.org/html/rfc4511>
