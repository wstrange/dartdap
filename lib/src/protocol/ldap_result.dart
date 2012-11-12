part of ldap_protocol;

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
  
  LDAPResult(_resultCode,_diagnosticMessage);
   
  LDAPResult.fromSequence(ASN1Sequence s) {
    
    ASN1Integer rc = s.elements[0];
    _resultCode = rc.intValue;
    logger.finest("LDAPResult code=${_resultCode}, elements=${s.elements}");
    var mv = s.elements[1] as ASN1OctetString;
    _matchedDN = mv.stringValue;
    var dm = s.elements[2] as ASN1OctetString;
    _diagnosticMessage = dm.stringValue;
    
    
    if( s.elements.length > 3) {
      // collect refs.... we dont really deal with these now...
      var rs = s.elements[3] as ASN1Sequence;
      _referralURLs = new List.from(rs.elements);
    }
    
  }
}
