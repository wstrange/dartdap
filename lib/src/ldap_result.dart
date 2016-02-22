library ldap_result;

import 'attribute.dart';

/**
 * Various ldap result objects
 */

/**
* LDAPResult - Sequuence
 *   resultCode (ENUM), matchedDN, errorMessage, referral (optional)
 *
 *
 *   Result Code
 *
 *   success                      (0),
                             operationsError              (1),
                             protocolError                (2),
                             timeLimitExceeded            (3),
                             sizeLimitExceeded            (4),
                             compareFalse                 (5),
                             compareTrue                  (6),

                             authMethodNotSupported       (7),
                             strongAuthRequired           (8),
                                        -- 9 reserved --
                             referral                     (10),  -- new
                             adminLimitExceeded           (11),  -- new
                             unavailableCriticalExtension (12),  -- new
                             confidentialityRequired      (13),  -- new
                             saslBindInProgress           (14),  -- new
                             noSuchAttribute              (16),
                             undefinedAttributeType       (17),
                             inappropriateMatching        (18),
                             constraintViolation          (19),
                             attributeOrValueExists       (20),
                             invalidAttributeSyntax       (21),
                                        -- 22-31 unused --
                             noSuchObject                 (32),
                             aliasProblem                 (33),
                             invalidDNSyntax              (34),
                             -- 35 reserved for undefined isLeaf --
                             aliasDereferencingProblem    (36),
                                        -- 37-47 unused --
                             inappropriateAuthentication  (48),
                             invalidCredentials           (49),
                             insufficientAccessRights     (50),
                             busy                         (51),
                             unavailable                  (52),
                             unwillingToPerform           (53),
                             loopDetect                   (54),
                                        -- 55-63 unused --
                             namingViolation              (64),
                             objectClassViolation         (65),
                             notAllowedOnNonLeaf          (66),
                             notAllowedOnRDN              (67),
                             entryAlreadyExists           (68),
                             objectClassModsProhibited    (69),
                                        -- 70 reserved for CLDAP --
                             affectsMultipleDSAs          (71), -- new
                                        -- 72-79 unused --
                             other                        (80) },
                             -- 81-90 reserved for APIs --
                matchedDN       LDAPDN,
                errorMessage    LDAPString,
                referral        [3] Referral OPTIONAL }
 *
 *
 */

/**
 * Generic LDAP Result
 */

class LDAPResult {
  //ResultCode _resultCode;
  int _resultCode;
  String _diagnosticMessage;
  String _matchedDN;
  List<String> _referralURLs;

  int get resultCode => _resultCode;
  String get diagnosticMessage => _diagnosticMessage;
  String get matchedDN => _matchedDN;
  List<String> get referralURLs => _referralURLs;

  LDAPResult(this._resultCode, this._matchedDN, this._diagnosticMessage,
      this._referralURLs);

  String toString() =>
      "${formatResultCode(resultCode)} msg=$_diagnosticMessage dn=$matchedDN";
}

/**
 * Holds a single SearchEntry result for a DN
 */
class SearchEntry {
  String _dn;
  String get dn => _dn;

  Map<String, Attribute> _attributes = new Map<String, Attribute>();
  Map<String, Attribute> get attributes => _attributes;

  SearchEntry(this._dn);

  String toString() => "Entry[$_dn,$_attributes]";
}

String formatResultCode(int code) => "${ResultCode.getMessage(code)} ($code)";

/**
 * LDAP Result Codes
 */
class ResultCode {
  static const int OK = 0;
  static const int OPERATIONS_ERROR = 1;
  static const int PROTOCOL_ERROR = 2;
  static const int TIME_LIMIT_EXCEEDED = 3;
  static const int SIZE_LIMIT_EXCEEDED = 4;
  static const int COMPARE_FALSE = 5;
  static const int COMPARE_TRUE = 6;
  static const int AUTH_METHOD_NOT_SUPPORTED = 7;
  static const int STRONG_AUTH_REQUIRED = 8;
  static const int REFERRAL = 9;
  static const int ADMIN_LIMIT_EXCEEDED = 11;
  static const int UNAVAILABLE_CRITICAL_EXTENSION = 12;
  static const int CONFIDENTIALITY_REQUIRED = 13;
  static const int SASL_BIND_IN_PROGRESS = 14;
  static const int NO_SUCH_ATTRIBUTE = 16;
  static const int UNDEFINED_ATTRIBUTE_TYPE = 17;
  static const int INAPPROPRIATE_MATCHING = 18;
  static const int CONSTRAINT_VIOLATION = 19;
  static const int ATTRIBUTE_OR_VALUE_EXISTS = 20;
  static const int INVALID_ATTRIBUTE_SYNTAX = 21;
  static const int NO_SUCH_OBJECT = 32;
  static const int ALIAS_PROBLEM = 33;
  static const int INVALID_DN_SYNTAX = 34;
  static const int IS_LEAF = 35;
  static const int ALIAS_DEREFERENCING_PROBLEM = 36;
  static const int INAPPROPRIATE_AUTHENTICATION = 48;
  static const int INVALID_CREDENTIALS = 49;
  static const int INSUFFICIENT_ACCESS_RIGHTS = 50;
  static const int BUSY = 51;
  static const int UNAVAILABLE = 52;
  static const int UNWILLING_TO_PERFORM = 53;
  static const int LOOP_DETECT = 54;
  static const int NAMING_VIOLATION = 64;
  static const int OBJECT_CLASS_VIOLATION = 65;
  static const int NOT_ALLOWED_ON_NONLEAF = 66;
  static const int NOT_ALLOWED_ON_RDN = 67;
  static const int ENTRY_ALREADY_EXISTS = 68;
  static const int OBJECT_CLASS_MODS_PROHIBITED = 69;
  static const int AFFECTS_MULTIPLE_DSAS = 71;
  static const int OTHER = 80;

  static String getMessage(int code) {
    switch (code) {
      case OK:
        return "OK";
      case OPERATIONS_ERROR:
        return "Operations Error";
      case PROTOCOL_ERROR:
        return "Protocol Error";
      case TIME_LIMIT_EXCEEDED:
        return "Time Limit Exceeded";
      case SIZE_LIMIT_EXCEEDED:
        return "Size Limit Exceeded";
      case COMPARE_TRUE:
        return "Compare True";
      case COMPARE_FALSE:
        return "Compare False";
      case AUTH_METHOD_NOT_SUPPORTED:
        return "Auth Method Not supported";
      case STRONG_AUTH_REQUIRED:
        return "String Auth Required";
      case REFERRAL:
        return "Referral";
      case ADMIN_LIMIT_EXCEEDED:
        return "Admin Limit Exceeded";
      case UNAVAILABLE_CRITICAL_EXTENSION:
        return "UNAVAILABLE_CRITICAL_EXTENSION";
      case CONFIDENTIALITY_REQUIRED:
        return "CONFIDENTIALITY_REQUIRED";
      case SASL_BIND_IN_PROGRESS:
        return "SASL_BIND_IN_PROGRESS";
      case NO_SUCH_ATTRIBUTE:
        return "NO_SUCH_ATTRIBUTE";
      case UNDEFINED_ATTRIBUTE_TYPE:
        return "Undefined Attribute Type";
      case NO_SUCH_OBJECT:
        return "Object does not exist";
      case INVALID_CREDENTIALS:
        return "Invalid Credentials";
      case INSUFFICIENT_ACCESS_RIGHTS:
        return "Insufficient Access Rights";
      case ENTRY_ALREADY_EXISTS:
        return "Entry already exists";

      // todo: Finish Mapping these. Most of the common error codes
      // are mapped above.

      default:
        return "LDAP Error code ${code}";
    }
  }
}
