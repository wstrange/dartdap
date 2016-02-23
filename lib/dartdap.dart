/// Classes for implementing LDAP v3 clients.
///
/// Implemented operations include BIND, ADD, MODIFY, DEL, MODIFYDN, SEARCH, COMPARE
///
/// ## Usage
///
/// Create an LDAPConnection object and then invoke LDAP operations on it. The
/// LDAPConnection object can be created directly or using the LDAPConfiguration
/// to manage the connection settings.
///
/// ## Examples
///
/// See the [LDAPConfiguration] class for examples of how to connect to an LDAP
/// server.
///
/// ## Exceptions
///
/// This package throws instances of a subclass of the abstract [LdapException]
/// class. All the exceptions described in this section are subclasses of it.
///
/// The [LdapUsageException] is thrown when the package has been
/// incorrectly used (e.g. methods invoked with the wrong parameters).
///
/// The [LdapSocketException], and subclasses of it, are thrown when there
/// is a problem with the network connection. Most commonly,
/// [LdapSocketServerNotFoundException] when the server's host name is
/// incorrect or [LdapSocketRefusedException] when it cannot connect to
/// the LDAP server (e.g. wrong port number, is blocked, or the LDAP
/// directory is not running).
///
/// The [LdapParseException] is thrown if there is a parsing error with
/// the LDAP messages received.
///
/// Subclasses of the abstract [LdapResultException] are thrown when a
/// LDAP result is received indicating an error has occured.  Any LDAP
/// result code, except for "OK", "COMPARE_FALSE" or "COMPARE_TRUE", are
/// treated as an error (constants for the result codes are defined in the
/// [ResultCode] class). There are over 30 such classes, whose name all
/// are of the form "LdapResult...Exception".  Commonly encountered ones
/// are:
///
/// - [LdapResultInvalidCredentialsException] when the BIND distinguished
///   name or password are incorrect.
///
/// - [LdapResultNoSuchObjectException] when a necessary entry is missing.
///
/// - [LdapResultEntryAlreadyExistsException] when creating an
///   entry that already exists.
///
/// - [LdapResultObjectClassViolationException] when the LDAP schema rules
///   would be violated.
///
/// ## Logging
///
/// This package uses the Dart
/// [logging](https://pub.dartlang.org/packages/logging) package for
/// logging.
///
/// The logging is mainly useful for debugging the package.
///
/// The following loggers are used:
///
/// - Logger: `ldap.control`
///
///     - finest = parsing of controls
///
/// - Logger: `ldap.session`
///
///     - warnings = certificate issues
///     - fine = connections successfully established, and closing them
///     - finer = details about attempts to establish a connection
///
/// - Logger: `ldap.send.ldap` for the LDAP messages sent.
///
///     - fine = LDAP messages sent.
///     - finest = details of LDAP message construction
///
/// - Logger: `ldap.recv.ldap` for the LDAP messages received
///   (i.e. received ASN.1 objects processed as LDAP messages).
///
///     - fine = LDAP messages received.
///     - finer = LDAP messages processing.
///
/// - Logger: `ldap.recv.asn1` for the ASN.1 objects received (i.e. parsed
///   from the raw bytes received). Probably only useful when debugging the
///   dartdap package.
///
///     - fine = ASN.1 messages successfully parsed from the raw bytes
///     - finest = shows the actual bytes making up the value of the ASN.1 message
///
/// - Logger: `ldap.recv.bytes` for the raw bytes received from the
///   socket.  Probably only useful when debugging the dartdap package.
///
///     - fine = number of bytes raw read
///     - finer = parsing activity of converting the bytes into ASN.1 objects
///     - finest = shows the actual bytes received and the number in the buffer to parse
///
/// ### Logging Examples
///
/// To take advantage of the hierarchy of loggers, enable
/// `hierarchicalLoggingEnabled` and set the logging level on individual
/// loggers. If the logging level is not explicitly set on a logger,
/// it is inherited from its parent. The root logger is the ultimate
/// parent; and its logging level is initally Level.INFO.
///
/// For example, to view high level connection and LDAP messages send/received:
///
/// ```dart
/// import 'package:logging/logging.dart';
///
/// ...
///
/// Logger.root.onRecord.listen((LogRecord rec) {
///   print('${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec.message}');
/// });
///
/// hierarchicalLoggingEnabled = true;
///
/// new Logger("ldap.session").level = Level.FINE;
/// new Logger("ldap.send.ldap").level = Level.FINE;
/// new Logger("ldap.recv.ldap").level = Level.FINE;
/// ```
///
/// To debug messages received:
///
/// ```dart
/// new Logger("ldap.recv.ldap").level = Level.ALL;
/// new Logger("ldap.recv.asn1").level = Level.FINER;
/// new Logger("ldap.recv.bytes").level = Level.FINE;
/// ```
///
/// Note: in the above examples: SHOUT, SEVERE, WARNING and INFO will
/// still be logged (except for those loggers and their children where the
/// level has been set to Level.OFF). To disable those log messages
/// change the root logger from its default of Level.INFO to Level.OFF.
///
/// For example, to suppress all log messages (including suppressing
/// SHOUT, SEVERE, WARNING and INFO):
///
/// ```dart
/// Logger.root.level = Level.OFF;
/// ```
///
/// Or leave the root level at the default and only disable logging
/// from the package:
///
/// ```dart
/// new Logger("ldap").level = Level.OFF;
/// ```

library ldapclient;

export 'src/ldap_connection.dart';
export 'src/ldap_exception.dart';
export 'src/filter.dart';
export 'src/attribute.dart';
export 'src/ldap_result.dart';
export 'src/search_scope.dart';
export 'src/modification.dart';
export 'src/ldap_util.dart';
export 'src/ldap_configuration.dart';
export 'src/sort_key.dart';
export 'src/control/control.dart';
export 'src/search_result.dart';
