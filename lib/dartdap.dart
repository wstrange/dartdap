/// LDAP v3 client library.
///
/// Implemented operations include BIND, ADD, MODIFY, DEL, MODIFYDN, SEARCH, COMPARE
/// 
/// ## Usage
/// 
/// 1. Instantiate an [LdapConnection] object.
/// 2. Call its `connect` method to connect to the LDAP directory.
/// 3. Call its `bind` method to authenticate to the LDAP directory, if needed.
/// 4. Perform LDAP operations using methods on it (e.g. `search`, `add`, `delete`).
/// 5. Call its `close` method when finished.
/// 
/// Please see the README for more details on how to use this package.  In
/// addition, an overview of the exceptions used in this package can be found in
/// the base exception class [LdapException].
///
/// Developers wanting to modify the package, please see the DEVEL.md file.
/// 

library dartdap;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:dart_config/default_server.dart' as server_config;
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

part 'src/dartdap/ldap_configuration.dart';
