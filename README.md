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

## Logging

This package uses the Dart
[logging](https://pub.dartlang.org/packages/logging) package for
logging.

### Loggers used

#### Logger: `ldap.control`

- finest = parsing of controls

#### Logger: `ldap.session`

- warnings = certificate issues
- fine = connections successfully established, and closing them
- finer = details about attempts to establish a connection

#### Logger: `ldap.send.ldap`

Logging the LDAP messages sent.

- fine = LDAP messages sent.
- finest = details of LDAP message construction

#### Logger: `ldap.recv.ldap`

Logging the LDAP messages received (i.e. received ASN.1 objects
processed as LDAP messages).

- fine = LDAP messages received.
- finer = LDAP messages processing.

#### Logger: `ldap.recv.asn1`

Logging the ASN.1 objects received (i.e. parsed from the raw bytes
received). Probably only useful when debugging the dartdap package.

- fine = ASN.1 messages successfully parsed from the raw bytes
- finest = shows the actual bytes making up the value of the ASN.1 message

#### Logger: `ldap.recv.bytes`

Logging the raw bytes received from the socket.  Probably only useful
 when debugging the dartdap package.

- fine = number of bytes raw read
- finer = parsing activity of converting the bytes into ASN.1 objects
- finest = shows the actual bytes received and the number in the buffer to parse

### Examples

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


## TODO

* Documentation. For now please see integration_test.dart for sample usage
* Improve conciseness / usability of API
* Paged search
* VLV Search. See [https://tools.ietf.org/html/draft-ietf-ldapext-ldapv3-vlv-09]
* An LDIF parser would be nice for creating integration test data
* Do we need to implement flow control so the client does not overwhelm
  the server?

