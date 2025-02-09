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

The code should be formatted by running dart format (or by using the
'Reformat with Dart Style' command in WebStorm) before checking it in
to the git repository.

//----------------
*/

library;

export 'src/client/client.dart';
export 'src/core/core.dart';
export 'src/control/control.dart';
export 'src/utils.dart';
