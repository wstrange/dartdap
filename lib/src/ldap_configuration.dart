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

/// A LDAP configuration settings and a LDAP connection created from it.
///
/// Use an instance of this class to represent the LDAP server
/// settings (host, port, bind distinguished name, password, and
/// whether the connection uses TLS/SSL).
///
/// It is also used to obtain an [LDAPConnection] using those settings.
///
/// There are two ways to create an LDAP configuration:
///
/// * Providing the settings as parameters using the default constructor.
/// * Loading the settings from a YAML file using the fromFile constructor.

class LDAPConfiguration {

  // Constants

  static const String _DEFAULT_HOST = "localhost";
  static const int _STANDARD_LDAP_PORT = 389;
  static const int _STANDARD_LDAPS_PORT = 636;

  static const String _DEFAULT_CONFIG_NAME = "default";

  // Configuration settings

  /// The LDAP server hostname or IP address
  String host;

  /// The LDAP server port number
  int port;

  /// Whether the connection to the LDAP server uses TLS/SSL
  bool ssl;

  /// The distinguished name of the entry for the bind operation
  String bindDN;

  /// The password used for the bind operation
  String password;

  // File details (only used if object created by the fromFile constructor)

  String _fileName; // null if settings don't need to be loaded from file
  String _configName; // name of map to use in the YAML file

  // Cached connection

  LDAPConnection _connection; // null if not created

  // Set values
  //
  // This internal method is used by the default constructor and to
  // process settings loaded from a file. It applies all the default rules
  // for when values are not provided.

  void _setAll(
      String hostname, int port, bool ssl, String bindDN, String password) {
    this.host = (hostname != null) ? hostname : _DEFAULT_HOST;
    this.ssl = (ssl != null) ? ssl : false;
    this.port = (port != null)
        ? port
        : ((ssl) ? _STANDARD_LDAPS_PORT : _STANDARD_LDAP_PORT);
    this.bindDN = (bindDN != null) ? bindDN : "";
    this.password = (password != null) ? password : "";
  }

  /// Constructor for a new LDAP configuration.
  ///
  /// The [hostname] is the hostname of the LDAP server.
  ///
  /// The [port] is the port number of the LDAP server. It defaults to the
  /// standard LDAP port numbers: 389 when TLS is not used or 636 when TLS is
  /// used.
  ///
  /// Set [ssl] to true to connect over TLS, otherwise TLS is not used. It
  /// defaults to false.
  ///
  /// Set [bindDN] to the distinguish name for the bind. An empty string
  /// means to perform an anonymous bind.  It defaults to an empty string.
  ///
  /// Set [password] to the password for bind. It defaults to an empty string.
  ///
  /// To perform an anonymous bind, omit the [bindDN] and [password].
  ///
  /// Examples:
  ///
  ///      // Anonymous bind
  ///      LDAPConfiguration.settings("localhost");
  ///      LDAPConfiguration.settings("ldap.example.com", ssl: true);
  ///
  ///      // Authenticated bind
  ///      LDAPConfiguration.settings("ldap.example.com", ssl: true, bindDN: "cn=admin,dc=example,dc=com", password: "p@ssw0rd");

  LDAPConfiguration(String hostname, {bool ssl: false, int port: null,
      String bindDN: null, String password: null}) {
    _setAll(hostname, port, ssl, bindDN, password);
  }

  /// Constructor for a new LDAP configuration from a YAML file.
  ///
  /// The [fileName] is the name of a YAML file
  /// containing the LDAP connection settings.
  ///
  /// The optional parameter [configName] is the name of a Map in the YAML
  /// file. It defaults to "default".
  ///
  /// # Example
  ///
  ///     var ldapConfig = new LDAPConfiguration("ldap.yaml", "default");
  ///
  /// This example loads the LDAP configuration from a Map named "default" from
  /// the YAML file "ldap.yaml" in the current directory. That YAML file could
  /// contain:
  ///
  ///     default:
  ///       host: "ldap.example.com"
  ///       port: 389
  ///       ssl: false
  ///       bindDN: "cn=admin,dc=example,dc=com"
  ///       password: "p@ssw0rd"
  ///
  ///  The only mandatory attribute is "host". See the default constructor
  ///  for a description of the other attributes, and their values if they are not specified.

  LDAPConfiguration.fromFile(String fileName, [String configName]) {
    assert(fileName != null && fileName.isNotEmpty);
    assert(configName == null || configName.isNotEmpty);

    this._fileName = fileName;
    this._configName = (configName != null) ? configName : _DEFAULT_CONFIG_NAME;
  }

  /// Loads the settings from the YAML file, if needed.
  ///
  /// If the LDAPConfiguration was not created using the fromFile constructor, this method
  /// does nothign and returns immediately.

  Future _load_values() async {
    if (_fileName == null) {
      // No file to load: settings are already set
      return;
    } else {
      // Load settings from file

      var configMap = await server_config.loadConfig(_fileName);

      var m = configMap[_configName];

      if (m == null) {
        throw new LDAPException("${_fileName}: missing \"${_configName}\"");
      }
      if (!(m is Map)) {
        throw new LDAPException(
            "${_fileName}: \"${_configName}\" is not a map");
      }

      // Get and check the host

      var host_value = m["host"];
      if (host_value == null) {
        throw new LDAPException(
            "${_fileName}: \"${_configName}\" missing \"host\"");
      }
      if (!(host_value is String)) {
        throw new LDAPException(
            "${_fileName}: host in \"${_configName}\" is not a string");
      }

      // Get and check the port

      var port_value = m["port"];
      if (port_value != null && !(port_value is int)) {
        throw new LDAPException(
            "${_fileName}: port in \"${_configName}\" is not an int");
      }

      // Get and check the ssl

      var ssl_value = m["ssl"];
      if (ssl_value != null && !(ssl_value is bool)) {
        throw new LDAPException(
            "${_fileName}: ssl in \"${_configName}\" is not true/false");
      }

      // Get and check bindDN

      var bindDN_value = m["bindDN"];
      if (bindDN_value != null && !(bindDN_value is String)) {
        throw new LDAPException(
            "${_fileName}: bindDN in \"${_configName}\" is not a string");
      }

      // Get and check password

      var password_value = m["password"];
      if (password_value != null && !(password_value is String)) {
        throw new LDAPException(
            "${_fileName}: password in \"${_configName}\" is not a string");
      }

      this._setAll(
          host_value, port_value, ssl_value, bindDN_value, password_value);

      _fileName = null; // prevent future invocations from reloading it
      return;
    }
  }

  /// Return a Future<[LDAPConnection]> using this configuration.
  ///
  /// The connection is cached so that subsequent calls will return
  /// the same connection (unless it has been closed, in which case
  /// a new one will be created).
  ///
  /// If the optional parameter [doBind] is true (the default),
  /// the returned connection will also be bound using the configured DN and password.
  ///
  /// The LDAP connection can be closed by invoking the `close` method on the
  /// [LDAPConfiguration] or by invoking the [LDAPConnection.close] method on the
  /// connection object.  Either approach will cause subsequent calls to
  /// this [getConnection] method to open a new LDAP connection.

  Future<LDAPConnection> getConnection([bool doBind = true]) async {
    if (_connection != null && !_connection.isClosed()) {
      // Use cached connection
      return _connection;
    }

    // Get settings (loading them from the YAML file if necessary)

    await _load_values();

    // Connect

    logger.info(
        "LDAP connection: ${ssl ? "ldaps://" : "ldap://"}${host}:${port}");

    _connection = new LDAPConnection(host, port, ssl, bindDN, password);
    await _connection.connect();

    // Bind

    if (doBind) {
      var r = await _connection.bind();
      if (r.resultCode != 0) throw new LDAPException("BIND Failed", r);
    }

    return _connection;
  }

  /// Closes the [LDAPconnection] that was opened with [getConnection].

  Future close([bool immediate = false]) {
    if (_connection != null) {
      var f = _connection.close(immediate);
      _connection = null;
      return f;
    } else {
      assert(_connection != null);
      return null;
    }
  }
}
