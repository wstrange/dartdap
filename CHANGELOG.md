# Dartdap Change Log

* 0.2.2 2017-09-15

- Allow SecurityContext to be passed to LdapConnection and setProtocol to enable
client certificates or custom CA roots to be added.

* 0.2.1 2016-09-26

- Fixed bug when port number is null.

* 0.2.0 2016-09-22

- Fixed race condition with multiple open/bind/close operations in parallel.
- Implemented automatic mode for LdapConnection.
- Deprecated LDAPConfiguration.
- Moved parameters to bind method for re-binding with different credentials.

* 0.1.0 2016-07-21

- Refactored exceptions and created LdapResultExceptions for all result codes.
- Reformatted using Dart dartfmt for code consistency.
- Restructured libraries and organisation of files under the lib directory.

* 0.0.12 2016-07-22

- Fixed bug when parsing large response messages.

* 0.0.9 2016-01-19

- Hierarchical logging support added.
- More bytes received than for one ASN.1 object parsing fixed.
- Extra checks on substring filter pattern added.
- Unit tests refactored and execution requirements documented.

