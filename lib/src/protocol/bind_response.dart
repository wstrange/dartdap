
part of ldap_protocol;

/**
 * Bind response - LDAP Response
 *  SEQ 
 *    resultCode (Enum/Integer)
 *    matchedDN (possibly NULL)
 *    diagostic message (possibly null)
 */

class BindResponse extends ResponseOp {
  
  
  BindResponse(ASN1Sequence o) : super.fromSequence(o) {
   
//    /logger.fine("BindResponse = ${o}");
  }
  
}
