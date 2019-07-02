/// LDAP v3 client library.
///
/// Basic usage:
///
/// 1. Create an LDAP connection ([LdapConnection]).
/// 2. Perform LDAP operations (`search`, `add`, `modify`, `modifyDN`, `compare`, `delete`).
/// 3. Close the connection (`close`).
///
/// An overview of the exceptions used in this package can be found in the base
/// exception class [LdapException].

/*
//----------------
FOR DEVELOPERS:

### Style

The code attempts to follow the style described in [Effective Dart:
Style](https://www.dartlang.org/effective-dart/style/).

### Formatting

The code should be formatted by running _dartfmt_ (or by using the
"Reformat with Dart Style" command in WebStorm) before checking it in
to the git repository.

### TODO: Items to do

* Improve conciseness / usability of API
* Paged search
* VLV Search. See [https://tools.ietf.org/html/draft-ietf-ldapext-ldapv3-vlv-09]
* An LDIF parser would be nice for creating integration test data
* Do we need to implement flow control so the client does not overwhelm
  the server?

//----------------
*/

library dartdap;

export 'src/dartdap/client/connection_manager.dart';
export 'src/dartdap/client/ldap_connection.dart';
export 'src/dartdap/core/core.dart';
export 'src/dartdap/control/control.dart';
