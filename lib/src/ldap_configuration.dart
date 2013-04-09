library ldap_configuration;


import 'dart:async';
import 'package:dart_config/default_server.dart' as server_config;


import 'ldap_connection.dart';
import 'ldap_result.dart';
import 'ldap_exception.dart';

/*
 * Utility for reading and holding an LDAP connection configuration
 * and the underlying LDAP connetion
 *
 * host, port, bind dn, etc.
 */
class LDAPConfiguration {

  LDAPConnection connection;

  String _fileName;
  Map configMap;

  String get bindDN   => configMap['bindDN'];
  String get password => configMap['password'];
  String get host     => configMap['host'];
  int    get port     => configMap['port'];

  /*
   * Create a new LDAP configuration.
   * If [_fileName] is provided it is assumed to be a yaml file
   * containing the ldap connection parameters. It
   * defaults to ldap.yaml in the current directory if not provided.
   */
  LDAPConfiguration([this._fileName = 'ldap.yaml']);

  /* Create an LDAP configuration from the specified map. Take
   * care that the port number in the map is an integer value
   */
  LDAPConfiguration.fromMap(Map m) {
    configMap = m;
  }

  /* Return a Future<Map> with the connection configuration detais */
  Future<Map> getConfig() {
    if( configMap != null )
      return new Future.immediate(configMap);

    return server_config.loadConfig(_fileName).then(
      (Map cfg) { configMap = cfg; return configMap; });
  }

  /**
   * Return a Future<LDAPConnection> using this configuration.
   * The connection is cached so that subsequent calls will return
   * the same connection.
   * If the optional parameter [doBind] is true (the default),
   * the returned connection will also be bound using the configured DN and password
   */

  Future<LDAPConnection> getConnection([bool doBind = true]) {
    // if we have an existing connection - return that immediatley
    if( connection != null )
      return new Future.immediate(connection);

    var c = new Completer<LDAPConnection>();

    getConfig().then((Map m) {
      connection = new LDAPConnection(host,port,bindDN,password);
      connection.connect()
        .then( (_)  {
          if( doBind) {
            connection.bind().then( (LDAPResult r) {
              if( r.resultCode == 0)
                c.complete(connection);
              else
                c.completeError( new LDAPException("BIND Failed", r));
            });
          }
          else // no bind requested. Just complete with the connection
            c.complete(connection);
         })
        .catchError( (AsyncError e) {
          c.completeError(e);
        });
    });
    return c.future;
  }

}
