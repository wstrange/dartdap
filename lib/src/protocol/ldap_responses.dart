part of ldap_protocol;

/**
 * "Generic" type ldap responses. 
 */


/**
  BindResponse ::= [APPLICATION 1] SEQUENCE {

             COMPONENTS OF LDAPResult,
             serverSaslCreds    [7] OCTET STRING OPTIONAL }
             
 */

class BindResponse extends ResponseOp {
  BindResponse(ASN1Sequence o) : super(o) ;
}

/**
 * Search result done
 * 
 *    SearchResultDone ::= [APPLICATION 5] LDAPResult
 */

class SearchResultDone extends ResponseOp {
  SearchResultDone(ASN1Sequence s): super(s);
}

/**
ModifyResponse ::= [APPLICATION 7] LDAPResult

*/
class ModifyResponse extends ResponseOp {
  ModifyResponse(ASN1Sequence s): super(s);
}

/**
AddResponse ::= [APPLICATION 9] LDAPResult
*/

/**

DelResponse ::= [APPLICATION 11] LDAPResult
*/


/**

ModifyDNResponse ::= [APPLICATION 13] LDAPResult
*/

/**
 * 
CompareResponse ::= [APPLICATION 15] LDAPResult
*/

/**
ExtendedResponse ::= [APPLICATION 24] SEQUENCE {
COMPONENTS OF LDAPResult,
responseName     [10] LDAPOID OPTIONAL,
response         [11] OCTET STRING OPTIONAL }

*/

