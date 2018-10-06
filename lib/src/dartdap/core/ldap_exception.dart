part of dartdap;

//===============================================================

/// Abstract base class for all LDAP exceptions.
///
/// The _dartdap_ package throws instances of a subclass of the abstract
/// [LdapException] class.
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

// Note: this documentation should go into the README.md file, but in there
// the hyperlinks to the classes won't work. So it is better putting it
// here to make the documentation more useful.

abstract class LdapException implements Exception {
  String _message;

  String get message => _message;

  LdapException(this._message);

  String toString() => _message;
}

//===============================================================

/// Exception thrown when the library has been incorrectly used.

class LdapUsageException extends LdapException {
  LdapUsageException(String message) : super(message);
}

//===============================================================

/// Exception thrown when the configuration file contains errors.

class LdapConfigException extends LdapException {
  LdapConfigException(String message) : super(message);
}

//===============================================================

/// Exception thrown when an open connection has been disconnected.
///
/// This exception is thrown when an LDAP operation is attempted, but
/// the connection is no longer open because it had been disconnected.
/// Disconnections are outside the application's control: they can occur
/// because the LDAP directory server has timed-out or dropped the connection,
/// or because of network errors.
///
/// If this exception is thrown, the application has explicitly chosen to
/// run in manual mode and has not taken into account that connections can
/// get disconnected. If possible, use the automatic mode (which will
/// automatically reopen disconnected connections). Otherwise, if manual mode
/// is necessary, check that the connection is open before performing any
/// LDAP operation.
///
class LdapConnectionDisconnected extends LdapException {
  LdapConnectionDisconnected() : super("connection disconnected");
}

//===============================================================
// Exceptions for socket connection

/// Exception when a SocketException was raised.
///
/// The original [SocketException] can be obtained from the [socketException]
/// member.
///
class LdapSocketException extends LdapException {
  SocketException socketException;
  LdapSocketException(this.socketException,
      [String message = "Socket exception"])
      : super(message) {
    assert(socketException != null);
  }

  String toString() => socketException.toString();
}

/// Exception indicating the server was not found.
///
/// Often caused by the hostname or IP address is incorrect.
///
class LdapSocketServerNotFoundException extends LdapSocketException {
  String remoteServer;
  LdapSocketServerNotFoundException(SocketException se, this.remoteServer)
      : super(se, "Server not found") {
    assert(socketException != null);
    assert(socketException.osError != null);
    assert(socketException.osError.errorCode == 8);
  }

  String toString() => "Cannot connect to $remoteServer";
}

/// Exception indicating the LDAP/LDAPS port could not be connected to.
///
/// Often caused by the LDAP server not running, or access to it has been
/// blocked.
///
class LdapSocketRefusedException extends LdapSocketException {
  int localPort;
  String remoteServer;
  int remotePort;

  LdapSocketRefusedException(
      SocketException se, this.remoteServer, this.remotePort)
      : super(se, "Cannot establish connection") {
    assert(socketException != null);
    assert(socketException.osError != null);
    assert(socketException.osError.errorCode == 61);
    this.localPort = socketException.port;
  }

  String toString() =>
      "Cannot connect to $remoteServer:$remotePort from port $localPort";
}

//===============================================================

/// Exception when a bad certificate is encountered.
///
/// This exception can be avoided by providing a custom bad certificate
/// handler callback for [LdapConnection.badCertHandler].

class LdapCertificateException extends LdapException {
  X509Certificate certificate;
  LdapCertificateException(this.certificate) : super("Bad X.509 certificate");

  String toString() =>
      "$message: subject=${certificate.subject}; issuer=${certificate.issuer}";
}

//===============================================================

/// Exception when a problem is encountered with parsing received LDAP messages.
///
/// Probably indicates an implementation problem with the LDAP server or
/// a bug in this package.

class LdapParseException extends LdapException {
  LdapParseException(String message) : super(message);
}

//===============================================================
// LDAP Result exceptions

/// Exception when an unsuccessful LDAP result is received.
///
/// All [ResultCode] values - except OK, COMPARE_FALSE, and COMPARE_TRUE - have
/// a corresponding exception class that is a subclass of this class.

abstract class LdapResultException extends LdapException {
  LdapResult _result;
  LdapResult get result => _result;

  LdapResultException(this._result) : super("LDAP Result") {
    assert(result != null);
  }

  String toString() => _result.toString();
}

class LdapResultOperationsErrorException extends LdapResultException {
  LdapResultOperationsErrorException(LdapResult r) : super(r);
}

class LdapResultProtocolErrorException extends LdapResultException {
  LdapResultProtocolErrorException(LdapResult r) : super(r);
}

class LdapResultTimeLimitExceededException extends LdapResultException {
  LdapResultTimeLimitExceededException(LdapResult r) : super(r);
}

class LdapResultSizeLimitExceededException extends LdapResultException {
  LdapResultSizeLimitExceededException(LdapResult r) : super(r);
}

class LdapResultAuthMethodNotSupportedException extends LdapResultException {
  LdapResultAuthMethodNotSupportedException(LdapResult r) : super(r);
}

class LdapResultStrongAuthRequiredException extends LdapResultException {
  LdapResultStrongAuthRequiredException(LdapResult r) : super(r);
}

class LdapResultReferralException extends LdapResultException {
  LdapResultReferralException(LdapResult r) : super(r);
}

class LdapResultAdminLimitExceededException extends LdapResultException {
  LdapResultAdminLimitExceededException(LdapResult r) : super(r);
}

class LdapResultUnavailableCriticalExtensionException
    extends LdapResultException {
  LdapResultUnavailableCriticalExtensionException(LdapResult r) : super(r);
}

class LdapResultConfidentialityRequiredException extends LdapResultException {
  LdapResultConfidentialityRequiredException(LdapResult r) : super(r);
}

class LdapResultSaslBindInProgressException extends LdapResultException {
  LdapResultSaslBindInProgressException(LdapResult r) : super(r);
}

class LdapResultNoSuchAttributeException extends LdapResultException {
  LdapResultNoSuchAttributeException(LdapResult r) : super(r);
}

class LdapResultUndefinedAttributeTypeException extends LdapResultException {
  LdapResultUndefinedAttributeTypeException(LdapResult r) : super(r);
}

class LdapResultInappropriateMatchingException extends LdapResultException {
  LdapResultInappropriateMatchingException(LdapResult r) : super(r);
}

class LdapResultConstraintViolationException extends LdapResultException {
  LdapResultConstraintViolationException(LdapResult r) : super(r);
}

class LdapResultAttributeOrValueExistsException extends LdapResultException {
  LdapResultAttributeOrValueExistsException(LdapResult r) : super(r);
}

class LdapResultInvalidAttributeSyntaxException extends LdapResultException {
  LdapResultInvalidAttributeSyntaxException(LdapResult r) : super(r);
}

/// An LdapResult was received with a result code of "No Such Object".
///
/// The `result.matchedDN` member indicates the part of the DN that did match.
/// That is, it is not the actual DN of the missing object.
///
class LdapResultNoSuchObjectException extends LdapResultException {
  LdapResultNoSuchObjectException(LdapResult r) : super(r);
}

class LdapResultAliasProblemException extends LdapResultException {
  LdapResultAliasProblemException(LdapResult r) : super(r);
}

class LdapResultInvalidDnSyntaxException extends LdapResultException {
  LdapResultInvalidDnSyntaxException(LdapResult r) : super(r);
}

class LdapResultIsLeafException extends LdapResultException {
  LdapResultIsLeafException(LdapResult r) : super(r);
}

class LdapResultAliasDereferencingProblemException extends LdapResultException {
  LdapResultAliasDereferencingProblemException(LdapResult r) : super(r);
}

class LdapResultInappropriateAuthenticationException
    extends LdapResultException {
  LdapResultInappropriateAuthenticationException(LdapResult r) : super(r);
}

class LdapResultInvalidCredentialsException extends LdapResultException {
  LdapResultInvalidCredentialsException(LdapResult r) : super(r);
}

class LdapResultInsufficientAccessRightsException extends LdapResultException {
  LdapResultInsufficientAccessRightsException(LdapResult r) : super(r);
}

class LdapResultBusyException extends LdapResultException {
  LdapResultBusyException(LdapResult r) : super(r);
}

class LdapResultUnavailableException extends LdapResultException {
  LdapResultUnavailableException(LdapResult r) : super(r);
}

class LdapResultUnwillingToPerformException extends LdapResultException {
  LdapResultUnwillingToPerformException(LdapResult r) : super(r);
}

class LdapResultLoopDetectException extends LdapResultException {
  LdapResultLoopDetectException(LdapResult r) : super(r);
}

class LdapResultNamingViolationException extends LdapResultException {
  LdapResultNamingViolationException(LdapResult r) : super(r);
}

class LdapResultObjectClassViolationException extends LdapResultException {
  LdapResultObjectClassViolationException(LdapResult r) : super(r);
}

class LdapResultNotAllowedOnNonleafException extends LdapResultException {
  LdapResultNotAllowedOnNonleafException(LdapResult r) : super(r);
}

class LdapResultNotAllowedOnRdnException extends LdapResultException {
  LdapResultNotAllowedOnRdnException(LdapResult r) : super(r);
}

class LdapResultEntryAlreadyExistsException extends LdapResultException {
  LdapResultEntryAlreadyExistsException(LdapResult r) : super(r);
}

class LdapResultObjectClassModsProhibitedException extends LdapResultException {
  LdapResultObjectClassModsProhibitedException(LdapResult r) : super(r);
}

class LdapResultAffectsMultipleDsasException extends LdapResultException {
  LdapResultAffectsMultipleDsasException(LdapResult r) : super(r);
}

class LdapResultOtherException extends LdapResultException {
  LdapResultOtherException(LdapResult r) : super(r);
}

/// Exception for LDAP result codes that are not handled by their own exceptions.

class LdapResultUnknownCodeException extends LdapResultException {
  LdapResultUnknownCodeException(LdapResult r) : super(r);
}
