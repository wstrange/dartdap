# Dartdap Development Notes

This document describes the internal details of the dartdap package
and is intended for developers wanting to modify the dartdap code.
Developers who only want to use the dartdap package should only need
to read the README document.

## Coding conventions

### Style

The code attempts to follow the style described in [Effective Dart:
Style](https://www.dartlang.org/effective-dart/style/).

Note: class names of the form "LDAPXyz" will soon be renamed to be
"LdapXyz" to consistently follow the convention.

### Formatting

The code should be formatted by running _dartfmt_ (or by using the
"Reformat with Dart Style" command in WebStorm) before checking it in
to the git repository.

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

## TODO

* Improve conciseness / usability of API
* Paged search
* VLV Search. See [https://tools.ietf.org/html/draft-ietf-ldapext-ldapv3-vlv-09]
* An LDIF parser would be nice for creating integration test data
* Do we need to implement flow control so the client does not overwhelm
  the server?
