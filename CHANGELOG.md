# Dartdap Change Log

## 0.7.5

- Update asn1lib (fix for ASN1Object equals method which impacted ASN1Set)

## 0.7.4

- #63 handle underscore _ in query

## 0.7.3

- #60 Properly escape commas in ldap search and query

## 0.7.2

- Upgraded packages to support latest version

## 0.7.1

- Fixed paged search #58

## 0.7.0

- Fixed #56 (don't throw exception on unknown control)
- Upgraded SDK and asn1 dependencies.

## 0.6.5

- Upgraded asn1 and petitparser dependencies
- Upgraded to new dart linter. Applied lint rules.

## 0.6.3

- Fixed ASN.1 tag encoding bug on modrdn new superior. #48

## 0.6.2

Experimental refactor of LdapConnectionPool.

## 0.6.1

- Added a 30 second timeout to the socket.connect()
- Updated petitparser to fix deprecations
- Added a github workflow
- Reformated many dart files to pass the GH action check

## 0.6.0

- Simplfied connection.close(). Fixes #40. This delegates more responsibility to the library user
  to consume all the results before issuing a connection.close().
- Update pub deps to all null safety libs

## 0.5.0 Null Safety

- The LdapConnection class has been simplified, and no longer provides an automatic mode where a connection
  is automatically opened. The user must call open() and then bind(). Use the LdapConnectionPool class to
  for automatic handling of connections, binds and retries.
- The LdapConnectionPool is a work in progress and is very much incomplete. It will retry a failed connection
  a numerb of times
- SearchResult: The ldap result is now provided via a future. Use `await searchResult.getLdapResult()`.
  Previously you needed to wait until the search entry stream was closed to fetch the ldap result. This was
  error prone, as the consumer might try to access the result before the stream was closed.
- LdapConnection: isAuthenticated method has been removed. Instead, query the connection state enum for
  ConnectionState.bound
- The race condition test was removed as the protocol for connection.open() now blocks an attempt to open an already
  open connection.

## 0.4.4

- Added a SimplePagedResult Control and a sample
- Extensive update to remove use of the "new" keyword

## 0.4.3

Fix #28

## 0.4.2

- Fix missing dependency. Address some analyser warnings.

## 0.4.0-beta

- New Feature: LDAP query parser. implements <https://tools.ietf.org/html/rfc2254>
  See [ldap.query](https://pub.dev/documentation/dartdap/latest/dartdap/LdapConnection/query.html)
- Breaking change: The Filter.substring() constructor now specifies the attribute and patterns
  separately.
- Rorganized to use library imports and move away form using `part of`.

## 0.3.5

- Fix #22

## 0.3.4

- Fixes for #21

## 0.3.3

- socket.destroy() <https://github.com/wstrange/dartdap/issues/20>
- Experimental support for ldap search referrals: <https://github.com/wstrange/dartdap/issues/19>

## 0.3.2

- Bug fix for ASN1 lib. dartfmt

## 0.3.0

- tests compile \* but still need major refactoring. Getting this published so folks can use it again.

## 0.3.0-beta

- prepare for Dart 2.0. All tests except for search_test are broken, but the code works for Dart 2.0.

## 0.2.2 2017-09-15

- Allow SecurityContext to be passed to LdapConnection and setProtocol to enable
  client certificates or custom CA roots to be added.

## 0.2.1 2016-09-26

- Fixed bug when port number is null.

## 0.2.0 2016-09-22

- Fixed race condition with multiple open/bind/close operations in parallel.
- Implemented automatic mode for LdapConnection.
- Deprecated LDAPConfiguration.
- Moved parameters to bind method for re-binding with different credentials.

## 0.1.0 2016-07-21

- Refactored exceptions and created LdapResultExceptions for all result codes.
- Reformatted using Dart dartfmt for code consistency.
- Restructured libraries and organisation of files under the lib directory.

## 0.0.12 2016-07-22

- Fixed bug when parsing large response messages.

## 0.0.9 2016-01-19

- Hierarchical logging support added.
- More bytes received than for one ASN.1 object parsing fixed.
- Extra checks on substring filter pattern added.
- Unit tests refactored and execution requirements documented.
