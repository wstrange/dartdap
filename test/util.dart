/// Utility to load configurations from a YAML file.

import "dart:io";
import 'package:dartdap/dartdap.dart';
import 'package:logging/logging.dart';
import "package:yaml/yaml.dart";

//################################################################
// Names of common "well-known" directory configurations used by the tests.
//
// Note: like all directory configurations (including the default one, whose
// name is [Config.defaultDirectoryName]) these are optional. But if they
// are specified, they must have the expected properties otherwise the tests
// won't work as expected.

/// Name of a directory configuration that must use LDAPS (LDAP over TLS).

const ldapsDirectoryName = 'ldaps';

/// Name of a directory configuration that must use LDAP (i.e. without TLS).

const noLdapsDirectoryName = 'ldap';

//################################################################
/// Test configuration.

class Config {
  /// Constructor
  ///
  /// If the [filename] is provided, only that file will be used. Otherwise,
  /// it will try to use the preferred config file, but if that does not exist
  /// it will use the default config file. By convention, the default config
  /// file should always be available.

  Config({String filename, this.strict = true, bool logging = true}) {
    // Determine which file to open

    File file;
    if (filename == null) {
      // No filename specified: try looking for the preferred config file

      file = File(preferredConfigFilename);
      if (file.existsSync()) {
        _filename = preferredConfigFilename;
      } else {
        // Preferred config file not found: try looking for the default config
        file = File(defaultConfigFilename);
        if (file.existsSync()) {
          _filename = defaultConfigFilename;
        } else {
          throw ConfigException(
              'file not found: $preferredConfigFilename or $defaultConfigFilename');
        }
      }
    } else {
      file = File(filename);
      if (file.existsSync()) {
        _filename = filename;
      } else {
        throw ConfigException('file not found: $filename');
      }
    }
    assert(file != null);
    assert(_filename != null);

    try {
      // Parse the file as YAML

      final topLevel = loadYaml(file.readAsStringSync());
      if (topLevel is YamlMap) {
        // Check for unexpected items in the top level of YAML

        if (strict) {
          for (final key in topLevel.keys) {
            if (![_directoriesItem, _loggingItem].contains(key)) {
              throw ConfigFileException(_filename, 'unexpected item: "$key"');
            }
          }
        }

        // Parse the directories configurations

        final directoriesItem = topLevel[_directoriesItem];
        if (directoriesItem is YamlMap) {
          _parseDirectories(directoriesItem);
        } else if (directoriesItem == null) {
          _directories = {};
        } else {
          throw ConfigFileException(_filename, 'not map: "$_directoriesItem"');
        }

        // Parse the logging configurations

        final logConfig = topLevel[_loggingItem];
        if (logConfig is YamlMap) {
          _setupLogging(logConfig, logging: logging);
        } else if (logConfig != null) {
          throw ConfigFileException(_filename, 'not map: "$_loggingItem"');
        }
      } else if (topLevel == null) {
        // Ok for the file to contain no configurations
        _directories = {}; // empty map (i.e. no directories)
      } else {
        throw ConfigFileException(_filename, 'contents is not a YAML map');
      }
    } on YamlException catch (e) {
      throw ConfigFileException(_filename, 'contents is invalid YAML: $e');
    }
  }

  //================================================================
  // Static members

  /// Name of the preferred configuration file.
  ///
  /// If no file name was specified, it tries to use this file. If this file
  /// does not exist, it will use the default config file.

  static const preferredConfigFilename = 'test/CONFIG.yaml';

  /// Name of the default configuration file.
  ///
  /// If no file name was specified and the preferred config file does not
  /// exist, it will use this file. This file should always exist.

  static const defaultConfigFilename = 'test/CONFIG-default.yaml';

  /// Name of the default directory settings.
  ///
  /// This should be the directory used for the core tests (i.e. the ones that
  /// are expected to always run). Configuration files should always define
  /// setting for this directory.

  static const defaultDirectoryName = 'default';

  // The config file can have top level items with these names

  static const _directoriesItem = 'directories';
  static const _loggingItem = 'logging';

  //================================================================
  // Members

  // Name of the config file loaded
  String _filename;

  /// Unexpected content in the configuration file is ignored or is an error.
  bool strict;

  Map<String, ConfigDirectory> _directories;

  //================================================================
  // Methods

  //----------------------------------------------------------------
  /// Retrieve the names of all the directory configurations.

  Iterable<String> get directoryNames => _directories.keys;

  //----------------------------------------------------------------
  /// Indicates if the configuration specifies the named directory.
  ///
  /// The convenience method [hasDefaultDirectory] can be used for the default
  /// directory.

  bool hasDirectory(String name) => _directories.containsKey(name);

  //----------------------------------------------------------------
  /// Returns a string message if a directory has not been configured.
  ///
  /// Returns a string for use with a test or group's "skip" parameter, if
  /// the [name] directory is not in the configuration file. Otherwise, null
  /// is returned if the directory is configured.
  ///
  ///     test('foo', () { ... },
  ///        skip: config.missingDirectory('specialDirectoryName'));
  ///
  /// The convenience method [skipIfMissingDefaultDirectory] can be used for
  /// the default directory.

  String skipIfMissingDirectory(String name) => hasDirectory(name)
      ? null
      : 'configuration "$_filename" does not have a "$name" directory';

  //----------------------------------------------------------------
  /// Retrieves the configuration for the named directory.
  ///
  /// Retrieves the configuration for the directory with [name] or returns null
  /// if there is no directory configuration with that name.
  ///
  /// The convenience method [defaultDirectory] can be used for the default
  /// directory.

  ConfigDirectory directory(String name) => _directories[name];

  //----------------------------------------------------------------
  /// Indicates if the default directory has been specified.

  bool get hasDefaultDirectory => hasDirectory(defaultDirectoryName);

  //----------------------------------------------------------------
  /// Retrieves the default directory settings.

  ConfigDirectory get defaultDirectory => directory(defaultDirectoryName);

  //----------------------------------------------------------------
  /// To skip a test/group if the default directory has not been configured.

  String get skipIfMissingDefaultDirectory =>
      skipIfMissingDirectory(defaultDirectoryName);

  //================================================================
  // Internal methods used by the constructor

  //----------------------------------------------------------------

  void _parseDirectories(YamlMap item) {
    _directories = {};

    for (final name in item.keys) {
      if (name is String) {
        final d = item[name];

        if (d is! YamlMap) {
          throw ConfigFileException(
              _filename, 'not map: "$_directoriesItem/$name"');
        }

        const _itemHost = 'host';
        const _itemPort = 'port';
        const _itemTls = 'tls';
        const _itemValidateCertificate = 'validate-certificate';
        const _itemBindDn = 'bindDN';
        const _itemPassword = 'password';
        const _itemBaseDn = 'baseDN';

        if (strict) {
          // Check for unexpected items in the directory configuration
          for (final key in d.keys) {
            if (![
              _itemHost,
              _itemPort,
              _itemTls,
              _itemValidateCertificate,
              _itemBindDn,
              _itemPassword,
              _itemBaseDn,
            ].contains(key)) {
              // key is not one of the expected items

              final correctKey = {
                'hostname': _itemHost,
                'address': _itemHost,
                'ssl': _itemTls,
                'SSL': _itemTls,
                'TLS': _itemTls,
                'validate': _itemValidateCertificate,
                'validatecert': _itemValidateCertificate,
                'validateCert': _itemValidateCertificate,
                'validate-cert': _itemValidateCertificate,
                'validatecertificate': _itemValidateCertificate,
                'validateCertificate': _itemValidateCertificate,
                'verify': _itemValidateCertificate,
                'verifycert': _itemValidateCertificate,
                'verifyCert': _itemValidateCertificate,
                'verify-cert': _itemValidateCertificate,
                'verifycertificate': _itemValidateCertificate,
                'verifyCertificate': _itemValidateCertificate,
                'verify-certificate': _itemValidateCertificate,
                'binddn': _itemBindDn,
                'binddN': _itemBindDn,
                'bindDn': _itemBindDn,
                'passwd': _itemPassword,
                'secret': _itemPassword,
                'basedn': _itemBaseDn,
                'baseDn': _itemBaseDn,
                'basedN': _itemBaseDn,
              }[key];

              final suggestion =
              (correctKey != null) ? ' (use "$correctKey")' : '';
              throw ConfigFileException(_filename,
                  'unexpected item: "$_directoriesItem/$name/$key"$suggestion');
            }
          }
        }

        // Note: the name "tls" is used because it is shorter than "ssl/tls" and is
        // more correct than "ssl". SSL and TLS are technically different protocols.
        // Ever since Heartbleed and other vulnerabilities were found in SSL 3.0,
        // SSL has been deprecated and should not be in active used -- only TLS
        // should be used.

        final dir = ConfigDirectory();

        dir.host = _getString(d, name, _itemHost);
        dir.ssl = _getBool(d, name, _itemTls, defaultValue: false);
        dir.port =
            _getInt(d, name, _itemPort, defaultValue: dir.ssl ? 636 : 389);
        dir.bindDN = _getString(d, name, _itemBindDn);
        dir.password = _getString(d, name, _itemPassword);
        dir.validateCertificate =
            _getBool(d, name, _itemValidateCertificate, defaultValue: true);
        dir.baseDN = _getString(d, name, _itemBaseDn);

        if (dir.host == null) {
          throw ConfigFileException(
              _filename, 'missing: "$_directoriesItem/$name/$_itemHost"');
        }
        if (dir.port < 1 || 65535 < dir.port) {
          throw ConfigFileException(
              _filename, 'out of range: "$_directoriesItem/$name/$_itemPort"');
        }

        if (dir.bindDN != null && dir.password == null) {
          throw ConfigFileException(_filename,
              '$_itemBindDn without $_itemPassword: "$_directoriesItem/$name"');
        }

        // Store the directory configuration in the map

        _directories[name] = dir;
      } else {
        throw ConfigFileException(_filename,
            'directory name is not a string: "$_directoriesItem/$name"');
      }
    }
  }

  //----------------------------------------------------------------
  /// Set up logging
  ///
  /// Parses the [logConfig] for logger names and logging levels.
  /// Also sets up logging using those levels if [logging] is not false.
  ///
  /// ```
  /// logging:
  ///    "*": INFO
  ///   ldap: INFO
  ///   ldap.connection: FINE
  ///   ldap.send.ldap: INFO
  ///   ldap.send.bytes: INFO
  ///   ldap.recv.bytes: INFO
  ///   ldap.recv.asn1: INFO
  /// ```

  void _setupLogging(YamlMap logConfig, {bool logging}) {
    // Only use the logging configuration if the program did not explicitly
    // set [logging] to false. But even if logging is not used, it is still
    // parsed by this method to check for errors.

    final useLogging = logging ?? true;

    if (useLogging) {
      hierarchicalLoggingEnabled = true;

      Logger.root.onRecord.listen((LogRecord r) {
        stdout.write(
            '${r.time}: ${r.loggerName}: ${r.level.name}: ${r.message}\n');
      });

      Logger.root.level = Level.OFF;
    }

    for (final key in logConfig.keys) {
      final value = logConfig[key];
      Level level;

      if (value is String) {
        switch (value) {
          case 'off':
          case 'OFF':
            level = Level.OFF;
            break;
          case 'shout':
          case 'SHOUT':
            level = Level.SHOUT;
            break;
          case 'severe':
          case 'SEVERE':
            level = Level.SEVERE;
            break;
          case 'warning':
          case 'WARNING':
            level = Level.WARNING;
            break;
          case 'info':
          case 'INFO':
            level = Level.INFO;
            break;
          case 'config':
          case 'CONFIG':
            level = Level.CONFIG;
            break;
          case 'fine':
          case 'FINE':
            level = Level.FINE;
            break;
          case 'finer':
          case 'FINER':
            level = Level.FINER;
            break;
          case 'finest':
          case 'FINEST':
            level = Level.FINEST;
            break;
          case 'all':
          case 'ALL':
            level = Level.ALL;
            break;
          default:
            throw ConfigFileException(_filename,
                'unsupported level name for "$_loggingItem/$key": "$value"');
            break;
        }
      } else if (value is int) {
        if (value < Level.ALL.value) {
          throw ConfigFileException(
              _filename, 'level is negative for "$_loggingItem/$key": $value');
        } else if (Level.SHOUT.value < value) {
          throw ConfigFileException(_filename,
              'level is larger than ${Level.SHOUT.value} for "$_loggingItem/$key": $value');
        }
        level = Level('custom', value);
      } else if (value is bool) {
        level = value ? Level.ALL : Level.OFF;
      } else {
        throw ConfigFileException(_filename,
            'expecting string or integer level for "$_loggingItem/$key"');
      }
      assert(level != null);

      if (key is String) {
        if (useLogging) {
          if (key == '*') {
            Logger.root.level = level; // set top level logger's level
          } else {
            Logger(key).level = level; // set the named logger's level
          }
        }
      } else {
        throw ConfigFileException(
            _filename, 'logger name must be a string: "$_loggingItem/$key"');
      }
    }
  }

  //================================================================
  // Internal method for parsing the YAML.

  String _getString(YamlMap map, String name, String param,
      {String defaultValue}) {
    final _value = map[param];
    if (_value is String) {
      return _value;
    } else if (_value == null) {
      return defaultValue;
    } else {
      throw ConfigFileException(
          _filename, 'value is not string: "$name/$param"');
    }
  }

  int _getInt(YamlMap map, String name, String param, {int defaultValue}) {
    final _value = map[param];
    if (_value is int) {
      return _value;
    } else if (_value == null) {
      return defaultValue;
    } else {
      throw ConfigFileException(_filename, 'value is not int: "$name/$param"');
    }
  }

  bool _getBool(YamlMap map, String path, String param, {bool defaultValue}) {
    final _value = map[param];
    if (_value is bool) {
      return _value;
    } else if (_value == null) {
      return defaultValue;
    } else {
      throw ConfigFileException(_filename, 'value is not bool: "$path/$param"');
    }
  }
}

//################################################################
/// Represents the configuration for a directory the tests can connect to.

class ConfigDirectory {
  String host;
  int port;
  bool ssl;
  String bindDN;
  String password;

  bool validateCertificate;
  String baseDN;

  //----------------------------------------------------------------
  /// Creates a connection using the settings.

  LdapConnection connect() => LdapConnection(
      host: host,
      ssl: ssl,
      port: port,
      bindDN: bindDN,
      password: password,
      badCertificateHandler:
          validateCertificate ? null : (X509Certificate _) => true);
}

//################################################################
/// Exception used by [Config].

class ConfigException implements Exception {
  const ConfigException(this.message);

  final String message;

  @override
  String toString() => 'config: $message';
}

//################################################################
/// Exception used by [Config] that includes the config filename.

class ConfigFileException extends ConfigException {
  const ConfigFileException(this.filename, String message) : super(message);

  final String filename;

  @override
  String toString() => '$filename: $message';
}
