
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

  // whether or not non zero ldap codes should generate an error
  // vs. just returning the LDAPResult code and letting the
  // caller check ther result.
  bool _errorOnNonZeroResult = true;

  /**
   * If a non zero LDAP result code is returned, trigger the
   * future's error method instead of returning the LDAPResult to
   * the completer.
   * Defaults to true.
   * This is used to create a more fluent style where the result code does
   * not always need to be checked.
   */
  set errorOnNonZeroResult(bool flag) => _errorOnNonZeroResult = flag;
  bool get errorOnNonZeroResult => _errorOnNonZeroResult;

  /**
   * Create a new LDAP connection to [host] and [port]
   * Optionally store a bind [dn] and [password] which can be used to
   * rebind to the connection
   */
  LDAPConnection(String host, int port, [this._bindDN, this._password]) {
    _cmgr = new ConnectionManager(host,port);
  }

  /*
   * Open a connection to the LDAP server. Note that this does NOT
   * perform a BIND operation.
   */
  Future<LDAPConnection> connect() {
    var c = new Completer<LDAPConnection>();
    _cmgr.connect().then( (cx) {
      c.complete(this);
    }).catchError( (AsyncError e) {
      logger.severe("Connect error ${e.error}");
      c.completeError(e);
    });

    return c.future;
  }
  /**
   * Bind to LDAP server. If the optional [bindDN] and [password] are not passed
   * the connection stored values are used for the bind.
   */
  Future<LDAPResult> bind([String bindDN, String password]) {
    if( ?bindDN )
      return _cmgr.process(new BindRequest(bindDN, password));
    else
      return _cmgr.process(new BindRequest(_bindDN, _password));
  }


  /**
   * Search Request
   */

  Future<SearchResult> search(String baseDN, Filter filter,
      List<String> attributes, {int scope: SearchScope.SUB_LEVEL}) =>
          _cmgr.process(new SearchRequest(baseDN,filter, attributes,scope));

  /**
   * Add a new LDAP entry.
   * [dn] is the LDAP Distinguised Name.
   * [attrs] is a map of attributes keyed by the attribute name. The
   *   attribute values can be simple Strings, lists of strings,
   *   or alternatively can be of type [Attribute]
   */

  Future<LDAPResult> add(String dn, Map<String,dynamic> attrs) =>
      _cmgr.process(new AddRequest(dn,Attributes.fromMap(attrs)));

  Future<LDAPResult> delete(String dn) => _cmgr.process(new DeleteRequest(dn));

  Future<LDAPResult> modify(String dn, Iterable<Modification> mods) =>
      _cmgr.process( new ModifyRequest(dn,mods));

  close([bool immediate = false]) => _cmgr.close(immediate);


}
