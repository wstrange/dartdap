import 'dn.dart';
import 'ldap_exception.dart';
import 'attribute.dart';
/**
 * Various ldap result objects
 */

/**
* LDAPResult - Sequence
 *   resultCode (ENUM), matchedDN, errorMessage, referral (optional)
 *
 *
 *   Result Code
 *
 *
 *                           success                      (0),
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

//===============================================================
/// Generic LDAP Result

class LdapResult {
  final int _resultCode;
  final String _diagnosticMessage;
  final String? _matchedDN;
  final List<String> _referralURLs;

  int get resultCode => _resultCode;
  String get diagnosticMessage => _diagnosticMessage;
  String? get matchedDN => _matchedDN;
  List<String> get referralURLs => _referralURLs;

  /// Constructor

  LdapResult(this._resultCode, this._matchedDN, this._diagnosticMessage, this._referralURLs);

  @override
  String toString() =>
      ResultCode.message(_resultCode) + _diagnosticMessage + (_matchedDN != null ? ': $_matchedDN' : '');

  /// Converts an LdapResult whose result code is an error into an exception.
  ///
  /// If the result code does not indicate an exception, null is returned.
  ///
  LdapException exceptionFromResultCode() {
    switch (resultCode) {
      case ResultCode.OPERATIONS_ERROR:
        return LdapResultOperationsErrorException(this);

      case ResultCode.PROTOCOL_ERROR:
        return LdapResultProtocolErrorException(this);

      case ResultCode.TIME_LIMIT_EXCEEDED:
        return LdapResultTimeLimitExceededException(this);

      case ResultCode.SIZE_LIMIT_EXCEEDED:
        return LdapResultSizeLimitExceededException(this);

      case ResultCode.AUTH_METHOD_NOT_SUPPORTED:
        return LdapResultAuthMethodNotSupportedException(this);

      case ResultCode.STRONG_AUTH_REQUIRED:
        return LdapResultStrongAuthRequiredException(this);

      case ResultCode.REFERRAL:
        return LdapResultReferralException(this);

      case ResultCode.ADMIN_LIMIT_EXCEEDED:
        return LdapResultAdminLimitExceededException(this);

      case ResultCode.UNAVAILABLE_CRITICAL_EXTENSION:
        return LdapResultUnavailableCriticalExtensionException(this);

      case ResultCode.CONFIDENTIALITY_REQUIRED:
        return LdapResultConfidentialityRequiredException(this);

      case ResultCode.SASL_BIND_IN_PROGRESS:
        return LdapResultSaslBindInProgressException(this);

      case ResultCode.NO_SUCH_ATTRIBUTE:
        return LdapResultNoSuchAttributeException(this);

      case ResultCode.UNDEFINED_ATTRIBUTE_TYPE:
        return LdapResultUndefinedAttributeTypeException(this);

      case ResultCode.INAPPROPRIATE_MATCHING:
        return LdapResultInappropriateMatchingException(this);

      case ResultCode.CONSTRAINT_VIOLATION:
        return LdapResultConstraintViolationException(this);

      case ResultCode.ATTRIBUTE_OR_VALUE_EXISTS:
        return LdapResultAttributeOrValueExistsException(this);

      case ResultCode.INVALID_ATTRIBUTE_SYNTAX:
        return LdapResultInvalidAttributeSyntaxException(this);

      case ResultCode.NO_SUCH_OBJECT:
        return LdapResultNoSuchObjectException(this);

      case ResultCode.ALIAS_PROBLEM:
        return LdapResultAliasProblemException(this);

      case ResultCode.INVALID_DN_SYNTAX:
        return LdapResultInvalidDnSyntaxException(this);

      case ResultCode.IS_LEAF:
        return LdapResultIsLeafException(this);

      case ResultCode.ALIAS_DEREFERENCING_PROBLEM:
        return LdapResultAliasDereferencingProblemException(this);

      case ResultCode.INAPPROPRIATE_AUTHENTICATION:
        return LdapResultInappropriateAuthenticationException(this);

      case ResultCode.INVALID_CREDENTIALS:
        return LdapResultInvalidCredentialsException(this);

      case ResultCode.INSUFFICIENT_ACCESS_RIGHTS:
        return LdapResultInsufficientAccessRightsException(this);

      case ResultCode.BUSY:
        return LdapResultBusyException(this);

      case ResultCode.UNAVAILABLE:
        return LdapResultUnavailableException(this);

      case ResultCode.UNWILLING_TO_PERFORM:
        return LdapResultUnwillingToPerformException(this);

      case ResultCode.LOOP_DETECT:
        return LdapResultLoopDetectException(this);

      case ResultCode.NAMING_VIOLATION:
        return LdapResultNamingViolationException(this);

      case ResultCode.OBJECT_CLASS_VIOLATION:
        return LdapResultObjectClassViolationException(this);

      case ResultCode.NOT_ALLOWED_ON_NONLEAF:
        return LdapResultNotAllowedOnNonleafException(this);

      case ResultCode.NOT_ALLOWED_ON_RDN:
        return LdapResultNotAllowedOnRdnException(this);

      case ResultCode.ENTRY_ALREADY_EXISTS:
        return LdapResultEntryAlreadyExistsException(this);

      case ResultCode.OBJECT_CLASS_MODS_PROHIBITED:
        return LdapResultObjectClassModsProhibitedException(this);

      case ResultCode.AFFECTS_MULTIPLE_DSAS:
        return LdapResultAffectsMultipleDsasException(this);

      case ResultCode.OTHER:
        return LdapResultOtherException(this);

      default:
        assert(resultCode != ResultCode.OK);
        assert(resultCode != ResultCode.COMPARE_FALSE);
        assert(resultCode != ResultCode.COMPARE_TRUE);
        return LdapResultUnknownCodeException(this);
    }
  }
}

//===============================================================
/// Search entry result produced by the search operation.
///
/// The [LdapConnection.search] method produces a [SearchResult] which
/// contains a stream of these objects: each representing an entry that matched
/// the search request.
///
/// Use the [dn] propperty to get the entry's distinguished name and the
/// [attributes] properties to get the attributes which were returned.
///
/// The server may return a list of referral URIs instead of search results. The
/// client can check for [hasReferrals] method

class SearchEntry {
  /// The entry's distinguished name.

  DN get dn => _dn;
  final DN _dn;

  final List<String> _referrals;

  bool get hasReferrals => _referrals.isNotEmpty;

  // Return the list of referrals. The search should be repeated
  // using these URIs
  List<String> get referrals => _referrals;

  /// Attributes returned by the search operation.
  ///
  /// This is a [Map] from the [String] name of the attribute to an [Attribute]
  /// object.

  Map<String, Attribute> get attributes => _attributes;

  final Map<String, Attribute> _attributes = <String, Attribute>{};

  /// Constructor

  SearchEntry(this._dn, {List<String> referrals = const []}) : _referrals = referrals;

  @override
  String toString() => 'Entry[$_dn,$_attributes]';
}

//===============================================================
/// LDAP Result Codes
class ResultCode {
  static const OK = 0;
  static const OPERATIONS_ERROR = 1;
  static const PROTOCOL_ERROR = 2;
  static const TIME_LIMIT_EXCEEDED = 3;
  static const SIZE_LIMIT_EXCEEDED = 4;
  static const COMPARE_FALSE = 5;
  static const COMPARE_TRUE = 6;
  static const AUTH_METHOD_NOT_SUPPORTED = 7;
  static const STRONG_AUTH_REQUIRED = 8;
  static const REFERRAL = 9;
  static const ADMIN_LIMIT_EXCEEDED = 11;
  static const UNAVAILABLE_CRITICAL_EXTENSION = 12;
  static const CONFIDENTIALITY_REQUIRED = 13;
  static const SASL_BIND_IN_PROGRESS = 14;
  static const NO_SUCH_ATTRIBUTE = 16;
  static const UNDEFINED_ATTRIBUTE_TYPE = 17;
  static const INAPPROPRIATE_MATCHING = 18;
  static const CONSTRAINT_VIOLATION = 19;
  static const ATTRIBUTE_OR_VALUE_EXISTS = 20;
  static const INVALID_ATTRIBUTE_SYNTAX = 21;
  static const NO_SUCH_OBJECT = 32;
  static const ALIAS_PROBLEM = 33;
  static const INVALID_DN_SYNTAX = 34;
  static const IS_LEAF = 35;
  static const ALIAS_DEREFERENCING_PROBLEM = 36;
  static const INAPPROPRIATE_AUTHENTICATION = 48;
  static const INVALID_CREDENTIALS = 49;
  static const INSUFFICIENT_ACCESS_RIGHTS = 50;
  static const BUSY = 51;
  static const UNAVAILABLE = 52;
  static const UNWILLING_TO_PERFORM = 53;
  static const LOOP_DETECT = 54;
  static const NAMING_VIOLATION = 64;
  static const OBJECT_CLASS_VIOLATION = 65;
  static const NOT_ALLOWED_ON_NONLEAF = 66;
  static const NOT_ALLOWED_ON_RDN = 67;
  static const ENTRY_ALREADY_EXISTS = 68;
  static const OBJECT_CLASS_MODS_PROHIBITED = 69;
  static const AFFECTS_MULTIPLE_DSAS = 71;
  static const OTHER = 80;

  // Important: do not add constants without also adding a message for it below,
  // creating a unique exception for it, and throwing that exception in
  // [_FuturePendingOp.processResult]

  static final Map<int, String> _messages = {
    OK: 'OK',
    OPERATIONS_ERROR: 'Operations error',
    PROTOCOL_ERROR: 'Protocol error',
    TIME_LIMIT_EXCEEDED: 'Time limit exceeded',
    SIZE_LIMIT_EXCEEDED: 'Size limit exceeded',
    COMPARE_FALSE: 'Compare false',
    COMPARE_TRUE: 'Compare true',
    AUTH_METHOD_NOT_SUPPORTED: 'Auth method not supported',
    STRONG_AUTH_REQUIRED: 'Strong auth required',
    REFERRAL: 'Referral',
    ADMIN_LIMIT_EXCEEDED: 'Admin limit exceeded',
    UNAVAILABLE_CRITICAL_EXTENSION: 'Unavailable critical extension',
    CONFIDENTIALITY_REQUIRED: 'Confidentiality required',
    SASL_BIND_IN_PROGRESS: 'SASL bind in progress',
    NO_SUCH_ATTRIBUTE: 'No such attribute',
    UNDEFINED_ATTRIBUTE_TYPE: 'Undefined attribute type',
    INAPPROPRIATE_MATCHING: 'Inappropriate matching',
    CONSTRAINT_VIOLATION: 'Constraint violation',
    ATTRIBUTE_OR_VALUE_EXISTS: 'Attribute or value exists',
    INVALID_ATTRIBUTE_SYNTAX: 'Invalid attribute syntax',
    NO_SUCH_OBJECT: 'No such object',
    ALIAS_PROBLEM: 'Alias problem',
    INVALID_DN_SYNTAX: 'Invalid DN syntax',
    IS_LEAF: 'Is leaf',
    ALIAS_DEREFERENCING_PROBLEM: 'Alias dereferencing problem',
    INAPPROPRIATE_AUTHENTICATION: 'Inappropriate authentication',
    INVALID_CREDENTIALS: 'Invalid credentials',
    INSUFFICIENT_ACCESS_RIGHTS: 'Insufficient access rights',
    BUSY: 'Busy',
    UNAVAILABLE: 'Unavailable',
    UNWILLING_TO_PERFORM: 'Unwilling to perform',
    LOOP_DETECT: 'Loop detect',
    NAMING_VIOLATION: 'Naming violation',
    OBJECT_CLASS_VIOLATION: 'Object class violation',
    NOT_ALLOWED_ON_NONLEAF: 'Not allowed on nonleaf',
    NOT_ALLOWED_ON_RDN: 'Not allowed on RDN',
    ENTRY_ALREADY_EXISTS: 'Entry already exists',
    OBJECT_CLASS_MODS_PROHIBITED: 'Object class mods prohibited',
    AFFECTS_MULTIPLE_DSAS: 'Affects multiple DSAS',
    OTHER: 'Other'
  };

  /// Returns a human readable string describing the result [code].

  static String message(int code) => _messages[code] ?? 'LDAP result code $code';

  //===============================================================

  /// The integer value of the result code.

  final int _value;

  /// Constructor from an integer value.

  ResultCode(this._value);

  /// The equality operator
  ///
  /// Returns true if and only if the [other] of the two are the same.

  @override
  bool operator ==(Object other) => (other is ResultCode && _value == other._value);

  @override
  String toString() => message(_value);

  @override
  int get hashCode => _value.hashCode;
}
