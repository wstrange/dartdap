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
IETF [RFC 4511](http://tools.ietf.org/html/rfc4511).

Breaking changes from previous versions are described at the
bottom of this page.

## Using dartdap

### Search example

To perform operations on an LDAP directory, the basic process is:

1. Create an LDAP connection (`LdapConnection`).
2. Perform LDAP operations (`search`, `add`, `modify`, `modifyDN`, `compare`, `delete`).
3. Close the connection (`close`).

```dart
import 'dart:async';

import 'package:dartdap/dartdap.dart';

Future example() async {

  // Create an LDAP connection object

  var host = "localhost";
  var ssl = false; // true = use LDAPS (i.e. LDAP over SSL/TLS)
  var port = null; // null = use standard LDAP/LDAPS port
  var bindDN = "cn=Manager,dc=example,dc=com"; // null=unauthenticated
  var password = "p@ssw0rd";

  var connection = new LdapConnection(host: host);
  connection.setProtocol(ssl, port);
  connection.setAuthentication(bindDN, password);

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
```

#### Create an LDAP connection

The first step is to instantiate an `LdapConnection` object using its
constructor.

These properties of the connection can be changed from their defaults:

- hostname (defaults to "localhost");
- ssl: false is plain LDAP, true is LDAPS (LDAP  over SSL/TLS) (defaults to false);
- port: port number (defaults to standard port for LDAP/LDAPS: 389 or 636);
- bindDN: distinguished name for binding, null means unauthenticated (default is null);
- password: password for binding.

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

There is *EXPERIMENTAL* support for search result references (referrals)

If SearchResult.referrals[] is not empty, it is an array or strings which are the DNs to repeat
the search request. The SDK does not automatically follow referrals.

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
  r = await ldap.compare("ou=Engineering,dc=example,dc=com",
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
  await ldap.delete("ou=Business Development,dc=example,dc=com");

} on LdapResultNoSuchObjectException catch (_) {
  // entry did not exist to delete

} on LdapException catch (e) {
  // some other problem
}
```

## Connecting and authenticating

The `LdapConnection` can operate in automatic or manual modes. The
mode can be set when it is created, or by using the `setAutomaticMode`
method.

In automatic mode (the default), it is not necessary to explicitly
connect or send LDAP BIND requests.

In automatic mode, the connection to the LDAP directory will be
established whenever it is needed. This will occur when the first LDAP
operation is performed. If it becomes disconnected (e.g. LDAP server
timeout), it will also re-establish the connection when the next LDAP
operation is performed.

In automatic mode, LDAP BIND requests will be made when necessary. For
example, if a bindDN and password has been set (via the constructor,
or the `setAuthentication` and `setAnonymous` methods), an LDAP BIND
request will be sent when the first LDAP operation is performed:
obviously, after the connection has been established and before the
operation's request.

There are `open` and `bind` methods to explicitly cause the connection
to be made and LDAP BIND request to be sent. But since these are
performed automatically, using them is optional in automatic
mode. However, an application might want to explicitly use them to
check the connection/authentication parameters; rather than have the
errors detected later when an LDAP operation is performed.

In manual mode, opening the connection and sending LDAP BIND requests
must be explicitly performed by the application. Exceptions will be
raised if the application fails to do this (e.g. attempting to perform
a search with a closed connection). In manual mode, if a disconnection
occurs subsequent LDAP operations will fail unless the application
re-opens the connection.

It is expected that most applications will use automatic mode.

The `state` property indicates what state the connection is in.

See the documentation of `LdapConnection` for more details.


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

- finest = parsing of controls

Logger: `ldap.session`

- warnings = certificate issues
- fine = connections successfully established, and closing them
- finer = details about attempts to establish a connection

Logger: `ldap.send.ldap` for the LDAP messages sent.

- fine = LDAP messages sent.
- finest = details of LDAP message construction

Logger: `ldap.send.bytes` for the raw bytes sent to the socket.
Probably only useful when debugging the dartdap package.

- severe = errors/exceptions when sending
- fine = number of raw bytes sent

Logger: `ldap.recv.ldap` for the LDAP messages receive
(i.e. received ASN.1 objects processed as LDAP messages).

- fine = LDAP messages received.
- finer = LDAP messages processing.

Logger: `ldap.recv.asn1` for the ASN.1 objects received (i.e. parsed
from the raw bytes received). Probably only useful when debugging the
dartdap package.

- fine = ASN.1 messages successfully parsed from the raw bytes
- finest = shows the actual bytes making up the value of the ASN.1 message

Logger: `ldap.recv.bytes` for the raw bytes received from the
  socket.  Probably only useful when debugging the dartdap package.

- fine = number of raw bytes read
- finer = parsing activity of converting the bytes into ASN.1 objects
- finest = shows the actual bytes received and the number in the buffer to parse

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
```


## Breaking changes

### Version 0.1.x to 0.2.x

- `LdapConnection` changed to support automatic
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

- The `search` method returns a _Future_ to a `SearchResult`.
  Previously, it returned the SearchResult synchronously.  This change
  was necessary because (with the introduction of automatic
  connections) a search could cause the connection to be opened, and
  bind request to be sent, before the search request is actually sent.

- Renaming of other classes and methods to consistently follow the
  Dart naming
  [conventions](https://www.dartlang.org/effective-dart/style/).  For
  example, `LDAPConnection` becomes `LdapConnection`, `LDAPResult`
  becomes `LdapResult`, `LDAPUtil` becomes `LdapUtil`.

- Exception raised if a bad certificate is encountered when opening a
  SSL/TLS connection. Provide a bad certificate handler function, if
  the application wants to override the default behaviour. Other than
  for testing, accepting bad certificates is a security risk: so, the
  default behaviour is the safer option.

- Internal classes hidden from public interface
  (e.g. `ConnectionManager`, `LDAPUtil`).

- `LDAPConfiguration` removed.

### Version 0.0.x to 0.1.x

- Library is now called "dartdap" instead of "ldap_client".  There was
  a disconnect in the naming: package X was imported, but only library
  Y was imported. That would have been ok if it had multiple
  libraries, but it currently only contains one publicly visible
  library. Also, many of the classes could apply an LDAP server too.

- `LDAPException` renamed to `LdapException` to follow the Dart naming
  [conventions](https://www.dartlang.org/effective-dart/style/).

- New exception classed defined for all the LDAP result error
  conditions. All LDAP operations now throws these new
  exceptions. Instead of checking the resultCode in the LDAPResult
  returned by the LDAP operations, catch the new exceptions.

- `SocketException` exceptions are now being internally caught and
  thrown as `LdapSocketException` objects. This make it easier to detect
  common failure conditions. Instead of catching `SocketException`,
  catch the new `LdapSocketException` or one of its subclasses.

- `LDAPConfiguration` is deprecated. Programs should use whatever
  configuration mechanism they normally use (e.g. databases or
  configuration files) rather than having to use a special
  configuration mechanism only for dartdap (and still having
  to use the other configuration mechanism for the rest of the
  program). It is also unsafe due to a race condition that could
  occur if multiple connections are being established.

- Internal organisation of libraries/imports/exports have been
  cleaned up. This should not be noticable by existing code,
  unless it was directly referencing those internal libraries
  or files.
