library ldap_configuration;


import 'dart:async';
import 'package:dart_config/default_server.dart' as server_config;
import 'package:logging/logging.dart';

import 'ldap_connection.dart';
import 'ldap_exception.dart';

/// Logger for the LDAP client library.
///
/// The logger name is "ldap_configuration".

Logger logger = new Logger("ldap_configuration");

/// A LDAP configuration settings and the underlying LDAP connection.
///
/// Use an instance of this class to represent the LDAP configuration
/// settings (host, port, bind distinguished name, password, and
/// whether the connection uses TLS/SSL).
///
/// It is also used to obtain an [LDAPConnection] using those settings.
///
/// # Example 1: settings from Map
///
/// Connects to an LDAP server using settings in a Map.
///
///     var ldap_settings = {
///       "default": {
///         "host": "10.211.55.35",
///         "port": 389,
///         "bindDN": "cn=admin,dc=example,dc=com",
///         "password": "p@ssw0rd",
///         "ssl": false
///       }
///     };
///     
///     var ldapConfig = new LDAPConfiguration.fromMap(ldap_settings);
///     
///     ldapConfig.getConnection().then((LDAPConnection ldap) {
///       var attrs = ["dn", "cn", "objectClass"];
///       var filter = Filter.present("objectClass");
///
///       ldap.search("dc=example,dc=com", filter, attrs).stream
///           .listen((SearchEntry entry) => print("Found $entry"));
///     });
///     
/// # Example 2: settings from YAML file
///
/// Connects to an LDAP server using settings in a YAML file.
///
///     var ldapConfig = new LDAPConfiguration("ldap.yaml", "default");
///     
///     ldapConfig.getConnection().then((LDAPConnection ldap) {
///       var attrs = ["dn", "cn", "objectClass"];
///       var filter = Filter.present("objectClass");
///
///       ldap.search("dc=example,dc=com", filter, attrs).stream
///           .listen((SearchEntry entry) => print('Found $entry'));
///     });
///
/// This example loads the LDAP configuration from a Map named "default" from
/// the YAML file "ldap.yaml" in the current directory. That YAML file could
/// contain:
///
///     default:
///       host: "ldap.example.com"
///       port: 389
///       bindDN: "cn=admin,dc=example,dc=com"
///       password: "p@ssw0rd"
///       ssl: false

class LDAPConfiguration {

  LDAPConnection _connection;

  String _fileName;
  Map configMap;

  String  _configName = "default";
  
  Map get config => configMap[_configName];

  /// Returns the binding distinguished name.
  String get bindDN   => config['bindDN'];
  /// Returns the password.
  String get password => config['password'];
  /// Returns the LDAP server host.
  String get host     => config['host'];
  /// Returns the LDAP server port number.
  int    get port     => config['port'];

  /// Returns true if the binding is TLS/SSL, false otherwise.
  bool get ssl {
    var x = config['ssl'];
    if( x == null || x != true)
      return false;
    return true;
  }

  /// Creates a new LDAP configuration from a configuration Map in a YAML file.
  ///
  /// If [_fileName] is provided it is used as the filename of a YAML file
  /// containing the LDAP connection parameters. It defaults to `ldap.yaml` in
  /// the current directory if not provided.
  /// 
  /// The optional parameter [_configName] is the name of a config in the YAML
  /// file. It defaults to "default".
  ///
  /// Example contents of the YAML file:
  ///
  ///     default:
  ///       host: "ldap.example.com"
  ///       port: 389
  ///       bindDN: "cn=admin,dc=example,dc=com"
  ///       password: "p@ssw0rd"
  ///       ssl: false

  LDAPConfiguration([this._fileName = 'ldap.yaml', this._configName = "default"]);


  /// Creates an LDAP configuration from a Map of values.
  ///
  /// The Map must contain an entry whose key is "default"
  /// and the value is a Map containing the settings.
  ///
  /// Note: unlike using the YAML file constructor, the name of the settings
  /// entry cannot be changed.
  ///
  /// The settings Map must contain these key-value pairs:
  ///
  /// * `host` - host name of IP address of LDAP server (String)
  /// * `port` - port number (**int**)
  /// * `bindDN` - distinguished name of binding entry (String)
  /// * `password` - credential to use for binding (String)
  ///
  /// These key-value pairs are optional:
  ///
  /// * `ssl` - true if binding using TLS/SSL (bool) - defaults to false

  LDAPConfiguration.fromMap(Map m) {
    configMap = m;
  }

  /// Return a Future<Map> with the connection configuration details.
  ///
  /// This method returns a Future because it might involve reading a file if
  /// the [LDAPConfiguration] was constructed by providing it with a filename
  /// for a YAML file.

  Future<Map> getConfig() async {
    if( configMap != null )
      return new Future.value(configMap);

    configMap = await server_config.loadConfig(_fileName);
    return configMap;
  }

  /// Return a Future<[LDAPConnection]> using this configuration.
  /// The connection is cached so that subsequent calls will return
  /// the same connection.
  ///
  /// If the optional parameter [doBind] is true (the default),
  /// the returned connection will also be bound using the configured DN and password
  ///
  /// The LDAP connection can be closed by invoking the `close` method on the
  /// [LDAPConfiguration] or by invoking the [LDAPConnection.close] method on the
  /// connection object.  Either approach will cause subsequent calls to
  /// this [getConnection] method to open a new LDAP connection.

  Future<LDAPConnection> getConnection   ([bool doBind = true])  async {
    // if we have an existing connection - return that immediatley
    if( _connection != null && ! _connection.isClosed())
      return  _connection;

    Map m = await getConfig();
    //
    logger.info("Connection params $host $port ssl=$ssl");
    _connection = new LDAPConnection(host,port,ssl,bindDN,password);
    await _connection.connect();

    if( doBind) {
      var r = await _connection.bind();
      if( r.resultCode != 0)
        throw new LDAPException("BIND Failed", r);
    }
    return _connection;
  }

  /// Closes the [LDAPconnection] that was opened with [getConnection].

  Future close([bool immediate = false]) {
    if( _connection == null)
      throw new LDAPException("Trying to close a null Connection");
    var f = _connection.close(immediate);
    _connection = null;
    return f;
  }
}
