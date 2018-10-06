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

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:logging/logging.dart';

import 'src/dartdap/protocol/ldap_protocol.dart'; // Internal library

// Parts

part 'src/dartdap/client/connection_manager.dart';
part 'src/dartdap/client/ldap_connection.dart';
part 'src/dartdap/client/ldap_transformer.dart';

part 'src/dartdap/control/control.dart';
part 'src/dartdap/control/server_side_sort.dart';
part 'src/dartdap/control/sort_key.dart';
part 'src/dartdap/control/virtual_list_view.dart';

part 'src/dartdap/core/attribute.dart';
part 'src/dartdap/core/filter.dart';
part 'src/dartdap/core/ldap_exception.dart';
part 'src/dartdap/core/ldap_result.dart';
part 'src/dartdap/core/ldap_util.dart';
part 'src/dartdap/core/modification.dart';
part 'src/dartdap/core/search_result.dart';
part 'src/dartdap/core/search_scope.dart';

/* Individual files in the internal library
part 'src/dartdap/protocol/add_request.dart';
part 'src/dartdap/protocol/bind_request.dart';
part 'src/dartdap/protocol/compare_request.dart';
part 'src/dartdap/protocol/delete_request.dart';
part 'src/dartdap/protocol/ldap_message.dart';
part 'src/dartdap/protocol/ldap_responses.dart';
part 'src/dartdap/protocol/moddn_request.dart';
part 'src/dartdap/protocol/modify_request.dart';
part 'src/dartdap/protocol/protocol_op.dart';
part 'src/dartdap/protocol/response_handler.dart';
part 'src/dartdap/protocol/search_request.dart';
part 'src/dartdap/protocol/search_result_entry.dart';
*/
