library ldap_exception;

import 'dart:io';
import 'ldap_result.dart';

//===============================================================

/// Base class for all LDAP exceptions.

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
// Exceptions for socket connection

/// Exception when there is a connection problem.

class LdapSocketException extends LdapException {
  SocketException socketException;
  LdapSocketException(this.socketException,
      [String message = "Socket exception"])
      : super(message) {
    assert(socketException != null);
  }

  String toString() => socketException.toString();
}

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

/// Exception when a problem is encountered with parsing received LDAP messages.

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
  LDAPResult _result;
  LDAPResult get result => _result;

  LdapResultException(this._result) : super("LDAP Result") {
    assert(result != null);
  }

  String toString() => _result.toString();
}

class LdapResultOperationsErrorException extends LdapResultException {
  LdapResultOperationsErrorException(LDAPResult r) : super(r);
}

class LdapResultProtocolErrorException extends LdapResultException {
  LdapResultProtocolErrorException(LDAPResult r) : super(r);
}

class LdapResultTimeLimitExceededException extends LdapResultException {
  LdapResultTimeLimitExceededException(LDAPResult r) : super(r);
}

class LdapResultSizeLimitExceededException extends LdapResultException {
  LdapResultSizeLimitExceededException(LDAPResult r) : super(r);
}

class LdapResultAuthMethodNotSupportedException extends LdapResultException {
  LdapResultAuthMethodNotSupportedException(LDAPResult r) : super(r);
}

class LdapResultStrongAuthRequiredException extends LdapResultException {
  LdapResultStrongAuthRequiredException(LDAPResult r) : super(r);
}

class LdapResultReferralException extends LdapResultException {
  LdapResultReferralException(LDAPResult r) : super(r);
}

class LdapResultAdminLimitExceededException extends LdapResultException {
  LdapResultAdminLimitExceededException(LDAPResult r) : super(r);
}

class LdapResultUnavailableCriticalExtensionException
    extends LdapResultException {
  LdapResultUnavailableCriticalExtensionException(LDAPResult r) : super(r);
}

class LdapResultConfidentialityRequiredException extends LdapResultException {
  LdapResultConfidentialityRequiredException(LDAPResult r) : super(r);
}

class LdapResultSaslBindInProgressException extends LdapResultException {
  LdapResultSaslBindInProgressException(LDAPResult r) : super(r);
}

class LdapResultNoSuchAttributeException extends LdapResultException {
  LdapResultNoSuchAttributeException(LDAPResult r) : super(r);
}

class LdapResultUndefinedAttributeTypeException extends LdapResultException {
  LdapResultUndefinedAttributeTypeException(LDAPResult r) : super(r);
}

class LdapResultInappropriateMatchingException extends LdapResultException {
  LdapResultInappropriateMatchingException(LDAPResult r) : super(r);
}

class LdapResultConstraintViolationException extends LdapResultException {
  LdapResultConstraintViolationException(LDAPResult r) : super(r);
}

class LdapResultAttributeOrValueExistsException extends LdapResultException {
  LdapResultAttributeOrValueExistsException(LDAPResult r) : super(r);
}

class LdapResultInvalidAttributeSyntaxException extends LdapResultException {
  LdapResultInvalidAttributeSyntaxException(LDAPResult r) : super(r);
}

class LdapResultNoSuchObjectException extends LdapResultException {
  LdapResultNoSuchObjectException(LDAPResult r) : super(r);
}

class LdapResultAliasProblemException extends LdapResultException {
  LdapResultAliasProblemException(LDAPResult r) : super(r);
}

class LdapResultInvalidDnSyntaxException extends LdapResultException {
  LdapResultInvalidDnSyntaxException(LDAPResult r) : super(r);
}

class LdapResultIsLeafException extends LdapResultException {
  LdapResultIsLeafException(LDAPResult r) : super(r);
}

class LdapResultAliasDereferencingProblemException extends LdapResultException {
  LdapResultAliasDereferencingProblemException(LDAPResult r) : super(r);
}

class LdapResultInappropriateAuthenticationException
    extends LdapResultException {
  LdapResultInappropriateAuthenticationException(LDAPResult r) : super(r);
}

class LdapResultInvalidCredentialsException extends LdapResultException {
  LdapResultInvalidCredentialsException(LDAPResult r) : super(r);
}

class LdapResultInsufficientAccessRightsException extends LdapResultException {
  LdapResultInsufficientAccessRightsException(LDAPResult r) : super(r);
}

class LdapResultBusyException extends LdapResultException {
  LdapResultBusyException(LDAPResult r) : super(r);
}

class LdapResultUnavailableException extends LdapResultException {
  LdapResultUnavailableException(LDAPResult r) : super(r);
}

class LdapResultUnwillingToPerformException extends LdapResultException {
  LdapResultUnwillingToPerformException(LDAPResult r) : super(r);
}

class LdapResultLoopDetectException extends LdapResultException {
  LdapResultLoopDetectException(LDAPResult r) : super(r);
}

class LdapResultNamingViolationException extends LdapResultException {
  LdapResultNamingViolationException(LDAPResult r) : super(r);
}

class LdapResultObjectClassViolationException extends LdapResultException {
  LdapResultObjectClassViolationException(LDAPResult r) : super(r);
}

class LdapResultNotAllowedOnNonleafException extends LdapResultException {
  LdapResultNotAllowedOnNonleafException(LDAPResult r) : super(r);
}

class LdapResultNotAllowedOnRdnException extends LdapResultException {
  LdapResultNotAllowedOnRdnException(LDAPResult r) : super(r);
}

class LdapResultEntryAlreadyExistsException extends LdapResultException {
  LdapResultEntryAlreadyExistsException(LDAPResult r) : super(r);
}

class LdapResultObjectClassModsProhibitedException extends LdapResultException {
  LdapResultObjectClassModsProhibitedException(LDAPResult r) : super(r);
}

class LdapResultAffectsMultipleDsasException extends LdapResultException {
  LdapResultAffectsMultipleDsasException(LDAPResult r) : super(r);
}

class LdapResultOtherException extends LdapResultException {
  LdapResultOtherException(LDAPResult r) : super(r);
}

/// Exception for LDAP result codes that are not handled by their own exceptions.

class LdapResultUnknownCodeException extends LdapResultException {
  LdapResultUnknownCodeException(LDAPResult r) : super(r);
}
