
library ldap_connection;

import 'package:logging/logging.dart';
import 'connection/connection_manager.dart';
import 'filter.dart';
import 'attribute.dart';
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

  Function onError;

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


  Future<LDAPResult> add(String dn, List<Attribute> attrs) =>
      _cmgr.process(new AddRequest(dn,attrs));

  Future<LDAPResult> delete(String dn) => _cmgr.process(new DeleteRequest(dn));

  close({bool immediate:false}) => _cmgr.close(immediate: immediate);


}
