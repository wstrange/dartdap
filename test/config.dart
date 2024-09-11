/// Utility to load configurations from a YAML file.

import 'dart:io';
import 'package:dartdap/dartdap.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

//################################################################
// Names of common 'well-known' directory configurations used by the tests.
//
// Note: like all directory configurations (including the default one, whose
// name is [Config.defaultDirectoryName]) these are optional. But if they
// are specified, they must have the expected properties otherwise the tests
// won't work as expected.

/// Name of a directory configuration that must use LDAPS (LDAP over TLS).

const ldapsDirectoryName = 'ldaps';

/// Name of a directory configuration that must use LDAP (i.e. without TLS).

const ldapDirectoryName = 'ldap';

LdapConnection defaultConnection() {
  var c = Config();
  return c.directory(Config.defaultDirectoryName).getConnection();
}

//################################################################
/// Test configuration.

class Config {
  /// Constructor
  ///
  /// If the [filename] is provided, only that file will be used. Otherwise,
  /// it will try to use the preferred config file, but if that does not exist
  /// it will use the default config file. By convention, the default config
  /// file should always be available.

  Config({String? filename, this.strict = true, bool logging = true}) {
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
          _setupLogging(logConfig, useLogging: logging);
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
  late String _filename;

  /// Unexpected content in the configuration file is ignored or is an error.
  bool strict;

  Map<String, ConfigDirectory> _directories = {};

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
  /// Returns a string for use with a test or group's 'skip' parameter, if
  /// the [name] directory is not in the configuration file. Otherwise, null
  /// is returned if the directory is configured.
  ///
  ///     test('foo', () { ... },
  ///        skip: config.missingDirectory('specialDirectoryName'));
  ///
  /// The convenience method [skipIfMissingDefaultDirectory] can be used for
  /// the default directory.

  String? skipIfMissingDirectory(String name) => hasDirectory(name)
      ? null
      : 'configuration "$_filename" does not have a "$name" directory';

  //----------------------------------------------------------------
  /// Retrieves the configuration for the named directory.
  ///
  /// Retrieves the configuration for the directory with [name].
  /// throws a Confi
  ///
  /// The convenience method [defaultDirectory] can be used for the default
  /// directory.

  ConfigDirectory directory(String name) {
    var d = _directories[name];
    if (d == null) {
      throw ConfigException('No Directory with name $name found');
    }
    return d;
  }

  //----------------------------------------------------------------
  /// Indicates if the default directory has been specified.

  bool get hasDefaultDirectory => hasDirectory(defaultDirectoryName);

  //----------------------------------------------------------------
  /// Retrieves the default directory settings.

  ConfigDirectory get defaultDirectory => directory(defaultDirectoryName);

  //----------------------------------------------------------------
  /// To skip a test/group if the default directory has not been configured.

  String? get skipIfMissingDefaultDirectory =>
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

        const itemHost = 'host';
        const itemPort = 'port';
        const itemSsl = 'ssl';
        const itemValidateCertificate = 'validate-certificate';
        const itemBindDn = 'bindDN';
        const itemPassword = 'password';
        const itemTestDn = 'testDN';

        if (strict) {
          // Check for unexpected items in the directory configuration
          for (final key in d.keys) {
            if (![
              itemHost,
              itemPort,
              itemSsl,
              itemValidateCertificate,
              itemBindDn,
              itemPassword,
              itemTestDn,
            ].contains(key)) {
              // key is not one of the expected items

              final correctKey = {
                'hostname': itemHost,
                'address': itemHost,
                'SSL': itemSsl,
                'TLS': itemSsl,
                'tls': itemSsl,
                'validate': itemValidateCertificate,
                'validatecert': itemValidateCertificate,
                'validateCert': itemValidateCertificate,
                'validate-cert': itemValidateCertificate,
                'validatecertificate': itemValidateCertificate,
                'validateCertificate': itemValidateCertificate,
                'verify': itemValidateCertificate,
                'verifycert': itemValidateCertificate,
                'verifyCert': itemValidateCertificate,
                'verify-cert': itemValidateCertificate,
                'verifycertificate': itemValidateCertificate,
                'verifyCertificate': itemValidateCertificate,
                'verify-certificate': itemValidateCertificate,
                'binddn': itemBindDn,
                'binddN': itemBindDn,
                'bindDn': itemBindDn,
                'passwd': itemPassword,
                'secret': itemPassword,
                'testdn': itemTestDn,
                'testDn': itemTestDn,
                'testdN': itemTestDn,
                'basedn': itemTestDn, // Calling this item 'testDN', because
                'baseDn': itemTestDn, // 'baseDN' easily mistaken for 'bindDN'.
                'basedN': itemTestDn,
              }[key];

              final suggestion =
                  (correctKey != null) ? ' (use "$correctKey)"' : '';
              throw ConfigFileException(_filename,
                  'unexpected item: "$_directoriesItem/$name/$key $suggestion');
            }
          }
        }

        final dir = ConfigDirectory();

        dir.host = _getString(d, name, itemHost);
        dir.ssl = _getBool(d, name, itemSsl, defaultValue: false);
        dir.port =
            _getInt(d, name, itemPort, defaultValue: dir.ssl ? 636 : 389);
        dir.bindDN = _getString(d, name, itemBindDn);
        dir.password = _getString(d, name, itemPassword);
        dir.validateCertificate =
            _getBool(d, name, itemValidateCertificate, defaultValue: true);

        final base = _getString(d, name, itemTestDn);
        if (base.isEmpty) {
          throw ConfigFileException(
              _filename, 'missing: "$_directoriesItem/$name/$itemTestDn"');
        }
        dir.testDN = DN(base);

        if (dir.host.isEmpty) {
          throw ConfigFileException(
              _filename, 'missing: "$_directoriesItem/$name/$itemHost"');
        }
        if (dir.port < 1 || 65535 < dir.port) {
          throw ConfigFileException(
              _filename, 'out of range: "$_directoriesItem/$name/$itemPort"');
        }

        if (dir.bindDN.isEmpty || dir.password.isEmpty) {
          throw ConfigFileException(_filename,
              '$itemBindDn without $itemPassword: "$_directoriesItem/$name"');
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
  ///    '*': INFO
  ///   ldap: INFO
  ///   ldap.connection: FINE
  ///   ldap.send.ldap: INFO
  ///   ldap.send.bytes: INFO
  ///   ldap.recv.bytes: INFO
  ///   ldap.recv.asn1: INFO
  /// ```

  void _setupLogging(YamlMap logConfig, {bool useLogging = true}) {
    // Only use the logging configuration if the program did not explicitly
    // set [logging] to false. But even if logging is not used, it is still
    // parsed by this method to check for errors.

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
                'unsupported level name for "$_loggingItem/$key": $value');
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
      {String defaultValue = ''}) {
    final value = map[param];
    if (value is String) {
      return value;
    } else if (value == null) {
      return defaultValue;
    } else {
      throw ConfigFileException(
          _filename, 'value is not string: "$name/$param"');
    }
  }

  int _getInt(YamlMap map, String name, String param, {int defaultValue = 0}) {
    final value = map[param];
    if (value is int) {
      return value;
    } else if (value == null) {
      return defaultValue;
    } else {
      throw ConfigFileException(_filename, 'value is not int: "$name/$param"');
    }
  }

  bool _getBool(YamlMap map, String path, String param,
      {bool defaultValue = false}) {
    final value = map[param];
    if (value is bool) {
      return value;
    } else if (value == null) {
      return defaultValue;
    } else {
      throw ConfigFileException(_filename, 'value is not bool: "$path/$param"');
    }
  }
}

//################################################################
/// Represents the configuration for a directory the tests can connect to.

// TOOD: As part of the null safety cleanup this should be refactored
// into an immutable class.
class ConfigDirectory {
  late String host;
  late int port;
  late bool ssl; // should be 'tls', but using ssl for consistency with dartdap
  late String bindDN;
  late String password;

  /// Perform certificate validation or not.
  /// Self-signed certificates can be used for testing, if this is set to false.
  late bool validateCertificate;

  /// Tests should confine themselves to this branch
  late DN testDN;

  //----------------------------------------------------------------
  /// Creates a connection using the settings.

  LdapConnection getConnection() => LdapConnection(
      host: host,
      ssl: ssl,
      port: port,
      bindDN: bindDN,
      password: password,
      badCertificateHandler: (X509Certificate _) => !validateCertificate);
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

// Utility to check attribute for non null and expected value
void expectSingleAttributeValue(
    SearchEntry entry, String attributeName, String expectedValue) {
  var attrs = entry.attributes[attributeName];
  if (attrs == null) {
    fail('Attribute $attributeName not found');
  }
  expect(attrs.values.length, equals(1));
  expect(attrs.values.first, equals(expectedValue));
}

// Utility to check attribute for non null and expected value startsWith
void expectSingleAttributeValueStartsWith(
    SearchEntry entry, String attributeName, String startsWith) {
  var attrs = entry.attributes[attributeName];
  if (attrs == null) {
    fail('Attribute $attributeName not found');
  }
  expect(attrs.values.length, equals(1));
  var s = attrs.values.first as String;
  expect(s.startsWith(startsWith), isTrue);
}

// Utility to print search results
Future<void> printSearchResults(SearchResult searchResult) async {
  var result = await searchResult.getLdapResult();
  print('got result = $result');
  if (result.resultCode == ResultCode.OK ||
      result.resultCode == ResultCode.SIZE_LIMIT_EXCEEDED) {
    print('ok');
    await searchResult.stream.forEach((entry) {
      print('entry: $entry');
    });
  } else {
    print('ldap error ${result.resultCode}');
  }
}
