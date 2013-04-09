library ldap_result;

import 'attribute.dart';

/**
 * Various ldap result objects
 */

/**
* LDAPResult - Sequnce
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



Wahl, et. al.               Standards Track                    [Page 16]

RFC 2251                         LDAPv3                    December 1997


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

  LDAPResult(this._resultCode,this._matchedDN,
      this._diagnosticMessage,this._referralURLs);

  String toString() => "LDAPResult code=$resultCode msg=$_diagnosticMessage dn=$matchedDN";

}


/*

todo: finish mapping these
18

INAPPROPRIATE_MATCHING (inappropriateMatching)

19

CONSTRAINT_VIOLATION (constraintViolation)

20

ATTRIBUTE_OR_VALUE_EXISTS (AttributeOrValueExists)

21

INVALID_ATTRIBUTE_SYNTAX (invalidAttributeSyntax)

32

NO_SUCH_OBJECT (noSuchObject)

33

ALIAS_PROBLEM (aliasProblem)

34

INVALID_DN_SYNTAX (invalidDNSyntax)

35

IS_LEAF (isLeaf)

36

ALIAS_DEREFERENCING_PROBLEM (aliasDereferencingProblem)

48

INAPPROPRIATE_AUTHENTICATION (inappropriateAuthentication)



50

INSUFFICIENT_ACCESS_RIGHTS (insufficientAccessRights)

51

BUSY (busy)

52

UNAVAILABLE (unavailable)

53

UNWILLING_TO_PERFORM (unwillingToPerform)

54

LOOP_DETECT (loopDetect)

64

NAMING_VIOLATION (namingViolation)

65

OBJECT_CLASS_VIOLATION (objectClassViolation)

66

NOT_ALLOWED_ON_NONLEAF (notAllowedOnNonLeaf)

67

NOT_ALLOWED_ON_RDN (notAllowedOnRDN)

68

ENTRY_ALREADY_EXISTS (entryAlreadyExists)

69

OBJECT_CLASS_MODS_PROHIBITED (objectClassModsProhibited)

71

AFFECTS_MULTIPLE_DSAS (affectsMultipleDSAs

80

OTHER (other)
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


  static const int INVALID_CREDENTIALS = 49;



  //static const int



  static String getMessage(int code) {
    switch(code) {
      case OK:                return "OK";
      case OPERATIONS_ERROR:  return "Operations Error";
      case COMPARE_TRUE:      return "Compare True";
      case COMPARE_FALSE:     return "Compare False";
      case AUTH_METHOD_NOT_SUPPORTED: return "Auth Method Not supported";
      case STRONG_AUTH_REQUIRED: return "String Auth Required";
      case REFERRAL:          return "Referral";
      case ADMIN_LIMIT_EXCEEDED: return "Admin Limit Exceeded";
      case UNAVAILABLE_CRITICAL_EXTENSION: return "UNAVAILABLE_CRITICAL_EXTENSION";
      case CONFIDENTIALITY_REQUIRED: return "CONFIDENTIALITY_REQUIRED";
      case SASL_BIND_IN_PROGRESS: return "SASL_BIND_IN_PROGRESS";
      case NO_SUCH_ATTRIBUTE: return "NO_SUCH_ATTRIBUTE";
      case UNDEFINED_ATTRIBUTE_TYPE: return "UNDEFINED_ATTRIBUTE_TYPE";
      case INVALID_CREDENTIALS: return "Invalid Credentials";



      default:                return "Error code ${code}";
    }
  }

}


class SearchResult {

  LDAPResult ldapResult;

  List<SearchEntry> _entries = new List();

  List<SearchEntry> get searchEntries => _entries;

  add(SearchEntry r) => _entries.add(r);

  String toString() {
    return _entries.toString();
  }
}

class SearchEntry {
  String _dn;

  String get dn => _dn;

  List<Attribute> _attributes = new List();
  List<Attribute> get attributes => _attributes;


  SearchEntry(this._dn,this._attributes);

  String toString() => "Entry[$_dn,$_attributes]";
}

