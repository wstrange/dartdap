
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

  String _host;
  int _port;
  String _connectDn = "";
  String _password;

  String get host => _host;
  int get port => _port;

  ConnectionManager _cmgr;

  Function onError; // global error handler

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

  LDAPConnection(this._host,this._port,[this._connectDn ,this._password]) {
    _cmgr = new ConnectionManager(this);
    _cmgr.connect();
  }

  /**
   * Bind to LDAP server
   */
  Future<LDAPResult> bind() =>
    _cmgr.process(new BindRequest(_connectDn, _password));


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

  close({bool immediate:false}) => _cmgr.close(immediate: immediate);


}
