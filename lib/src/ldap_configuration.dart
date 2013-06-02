library ldap_configuration;


import 'dart:async';
import 'package:dart_config/default_server.dart' as server_config;
import 'package:logging/logging.dart';



import 'ldap_connection.dart';
import 'ldap_result.dart';
import 'ldap_exception.dart';


Logger logger = new Logger("ldap_configuration");


/*
 * Holds LDAP connection configuration settings (host, port, bind dn, etc.)
 * and the underlying LDAP connection
 *
 */
class LDAPConfiguration {

  LDAPConnection _connection;

  String _fileName;
  Map configMap;

  String  _configName = "default";

  Map get config => configMap[_configName];

  String get bindDN   => config['bindDN'];
  String get password => config['password'];
  String get host     => config['host'];
  int    get port     => config['port'];

  bool get ssl {
    var x = config['ssl'];
    if( x == null || x != true)
      return false;
    return true;
  }

  /*
   * Create a new LDAP configuration.
   * If [fileName] is provided it is assumed to be a yaml file
   * containing the ldap connection parameters. It
   * defaults to ldap.yaml in the current directory if not provided.
   * The optional parameter [configName] is the name of a config in the config file
   *  It defaults to "default"
   */
  LDAPConfiguration([this._fileName = 'ldap.yaml', this._configName = "default"]);


  /**
   * Create an LDAP configuration from the specified map. Take
   * care that the port number in the map is an integer value
   */
  LDAPConfiguration.fromMap(Map m) {
    configMap = m;
  }

  /* Return a Future<Map> with the connection configuration detais */
  Future<Map> getConfig() {
    if( configMap != null )
      return new Future.value(configMap);

    return server_config.loadConfig(_fileName).then(
      (Map cfg) { configMap = cfg; return configMap; });
  }

  /**
   * Return a Future<LDAPConnection> using this configuration.
   * The connection is cached so that subsequent calls will return
   * the same connection.
   *
   *
   * If the optional parameter [doBind] is true (the default),
   * the returned connection will also be bound using the configured DN and password
   */

  Future<LDAPConnection> getConnection([bool doBind = true]) {
    // if we have an existing connection - return that immediatley
    if( _connection != null )
      return new Future(() => _connection);

    var c = new Completer<LDAPConnection>();

    getConfig().then((Map m) {
      //
      logger.info("Connection params $host $port ssl=$ssl");
      _connection = new LDAPConnection(host,port,ssl,bindDN,password);
      _connection.connect()
        .then( (_)  {
          if( doBind) {
            _connection.bind().then( (LDAPResult r) {
              if( r.resultCode == 0)
                c.complete(_connection);
              else
                c.completeError( new LDAPException("BIND Failed", r));
            });
          }
          else // no bind requested. Just complete with the connection
            c.complete(_connection);
         })
        .catchError( (e) {
          c.completeError(e);
        });
    });
    return c.future;
  }

  Future close([bool immediate = false]) {
    if( _connection == null)
      throw new LDAPException("Trying to close a null Connection");
    var f = _connection.close(immediate);
    _connection = null;
    return f;
  }
}
