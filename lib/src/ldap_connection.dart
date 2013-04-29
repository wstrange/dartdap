
library ldap_connection;

import 'package:logging/logging.dart';
import 'connection/connection_manager.dart';
import 'dart:async';
import 'filter.dart';
import 'attribute.dart';
import 'modification.dart';
import 'ldap_exception.dart';
import 'ldap_result.dart';
import 'protocol/ldap_protocol.dart';
import 'search_scope.dart';


class LDAPConnection {
  ConnectionManager _cmgr;

  String _bindDN;
  String _password;

  Function onError; // global error handler

  /**
   * Create a new LDAP connection to [host] and [port]
   *
   * Optionally store a bind [_bindDN] and [_password] which can be used to
   * rebind to the connection
   */
  LDAPConnection(String host, int port, [this._bindDN, this._password]) {
    _cmgr = new ConnectionManager(host,port);
  }

  /*
   * Open a connection to the LDAP server. This does NOT
   * perform a BIND operation. If the LDAP server
   * supports anonymous bind, you can send ldap commands
   * after the connect completes.
   *
   */
  Future<LDAPConnection> connect() {
    var c = new Completer<LDAPConnection>();
    _cmgr.connect().then( (cx) {
      c.complete(this);
    }).catchError( ( e) {
      logger.severe("Connect error ${e.error}");
      c.completeError(e);
    });
    return c.future;
  }

  /**
   * Bind to LDAP server. If the optional [bindDN] and [password] are not passed
   * the connections stored values are used for the bind.
   */
  Future<LDAPResult> bind([String bindDN, String password]) {
    if( ?bindDN )
      return _cmgr.process(new BindRequest(bindDN, password));
    else
      return _cmgr.process(new BindRequest(_bindDN, _password));
  }


  /*
   * Search for ldap entries, starting at the [baseDN],
   * specified by the search [filter].
   * Return the listed [attributes].
   *
   * [scope] is optional, and defaults to SUB_LEVEL (i.e.
   * search at base DN and all objects below it).
   *
   *
   */

  Stream<SearchEntry> search(String baseDN, Filter filter,
      List<String> attributes, {int scope: SearchScope.SUB_LEVEL}) =>
          _cmgr.processSearch(new SearchRequest(baseDN,filter, attributes,scope));

  /**
   * Add a new LDAP entry.
   * [dn] is the LDAP Distinguised Name.
   * [attrs] is a map of attributes keyed by the attribute name. The
   *   attribute values can be simple Strings, lists of strings,
   *   or alternatively can be of type [Attribute]
   */

  Future<LDAPResult> add(String dn, Map<String,dynamic> attrs) =>
      _cmgr.process(new AddRequest(dn,Attributes.fromMap(attrs)));

  // Delete the ldap entry identified by [dn]
  Future<LDAPResult> delete(String dn) => _cmgr.process(new DeleteRequest(dn));

  // Modify the ldap entry [dn] with the list of modifications [mods]
  Future<LDAPResult> modify(String dn, Iterable<Modification> mods) =>
      _cmgr.process( new ModifyRequest(dn,mods));

  // close the ldap connection. If [immediate] is true, close the
  // connection immediately. This could result in queued operations
  // being discarded
  close([bool immediate = false]) => _cmgr.close(immediate);
}
