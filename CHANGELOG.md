# Dartdap Change Log

* 0.0.10 2016-07-07

- Reformatted using Dart dartfmt for code consistency.
- Refactored exceptions and created LdapResultExceptions for all result codes.
- Restructured libraries and organisation of files under the lib directory.
- Deprecated LDAPConfiguration.
- Moved parameters to bind method for re-binding with different credentials.
- Fixed bug with processing received data with leftover data.

* 0.0.9 2016-01-15

- Hierarchical logging support added.
- More bytes received than for one ASN.1 object parsing fixed.
- Extra checks on substring filter pattern added.
- Unit tests refactored and execution requirements documented.

