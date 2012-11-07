
/*




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

49

INVALID_CREDENTIALS (invalidCredentials)

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
      
      
      
      default:                return "Error code ${code}";
    }
  }
 
  
}
