
library ldap_connection;

import 'package:logging/logging.dart';
import 'connection/connection_manager.dart';
import 'dart:async';
import 'filter.dart';
import 'attribute.dart';
import 'modification.dart';
import 'ldap_result.dart';
import 'protocol/ldap_protocol.dart';
import 'search_scope.dart';

/**
 * Operations that we can invoke on an LDAP server
 *
 * Most users will want to obtain a [LDAPConnection] using the
 * [LDAPConfiguration] class.
 *
 * With the exception of a BIND operation, LDAP operations
 * are asynchronous. We do not need to wait for the current
 * operation completes before sending the next one.
 *
 * LDAP return results are matched to requests using a message id. They
 * are not guaranteed to be returned in the same order they
 * were sent.
 *
 * There is currently no flow control. Messages will be queued and sent
 * to the LDAP server as fast as possible. Messages are sent in in the order in
 * which they are queued.
 *
 */
class LDAPConnection {
  ConnectionManager _cmgr;

  String _bindDN;
  String _password;

  Function onError; // global error handler

  /**
   * Create a new LDAP connection to [host] and [port].
   *
   * If [ssl] is true the connection will use SSL.
   *
   * Optionally store a bind [_bindDN] and [_password] which can be used to
   * rebind to the connection
   */
  LDAPConnection(String host, int port, [bool ssl =false, this._bindDN, this._password]) {
    _cmgr = new ConnectionManager(host,port,ssl);
  }

  /**
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
      logger.severe("Connect error ${e}");
      c.completeError(e);
    });
    return c.future;
  }

  /**
   * Perform an LDAP BIND. If the optional [bindDN] and [password] are not passed
   * the connections stored values are used for the bind.
   */
  Future<LDAPResult> bind({String bindDN:null, String password:null}) {
    if( bindDN != null )
      return _cmgr.process(new BindRequest(bindDN, password));
    else
      return _cmgr.process(new BindRequest(_bindDN, _password));
  }


  /**
   * Search for ldap entries, starting at the [baseDN],
   * specified by the search [filter].
   * Return the listed [attributes].
   *
   * [scope] is optional, and defaults to SUB_LEVEL (i.e.
   * search at base DN and all objects below it).
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

  /// Delete the ldap entry identified by [dn]
  Future<LDAPResult> delete(String dn) => _cmgr.process(new DeleteRequest(dn));

  /// Modify the ldap entry [dn] with the list of modifications [mods]
  Future<LDAPResult> modify(String dn, Iterable<Modification> mods) =>
      _cmgr.process( new ModifyRequest(dn,mods));

  /// Modify the Entries [dn] to a new relative [rdn]. If [deleteOldRDN] is true
  /// delete the old entry. If [newSuperior] is not null, reparent the entry
  Future<LDAPResult> modifyDN(String dn, String rdn,[bool deleteOldRDN = true, String newSuperior]) =>
      _cmgr.process(new ModDNRequest(dn,rdn,deleteOldRDN, newSuperior));

  /// perform an LDAP Compare operation on the [dn].
  /// Compare the [attrName] and [attrValue] to see if they are the same
  ///
  /// The completed [LDAPResult] will have a value of [ResultCode.COMPARE_TRUE]
  /// or [ResultCode.COMPARE_FALSE].
  Future<LDAPResult> compare(String dn,String attrName,String attrValue) =>
      _cmgr.process( new CompareRequest(dn, attrName, attrValue));

  // close the ldap connection. If [immediate] is true, close the
  // connection immediately. This could result in queued operations
  // being discarded
  close([bool immediate = false]) => _cmgr.close(immediate);
}
