part of ldap_protocol;

/// Defines various LDAP response types

//
// BindResponse ::= [APPLICATION 1] SEQUENCE {
//              COMPONENTS OF LDAPResult,
//              serverSaslCreds    [7] OCTET STRING OPTIONAL }

class BindResponse extends ResponseOp {
  BindResponse(LDAPMessage m) : super(m);
}

/// Search result done
///
///    SearchResultDone ::= [APPLICATION 5] LDAPResult

class SearchResultDone extends ResponseOp {
  SearchResultDone(LDAPMessage m) : super(m);
}

//  ModifyResponse ::= [APPLICATION 7] LDAPResult
//
class ModifyResponse extends ResponseOp {
  ModifyResponse(LDAPMessage m) : super(m);
}

/// A generic LDAP result.
/// This includes...
///      AddResponse ::= [APPLICATION 9] LDAPResult
///      DelResponse ::= [APPLICATION 11] LDAPResult
///      ModifyDNResponse ::= [APPLICATION 13] LDAPResult
///      CompareResponse ::= [APPLICATION 15] LDAPResult
///
class GenericResponse extends ResponseOp {
  GenericResponse(LDAPMessage m) : super(m);
}

// ExtendedResponse ::= [APPLICATION 24] SEQUENCE {
// COMPONENTS OF LDAPResult,
// responseName     [10] LDAPOID OPTIONAL,
// response         [11] OCTET STRING OPTIONAL }

class ExtendedResponse extends ResponseOp {
  static const int TYPE_EXTENDED_RESPONSE_OID = 0x8A;
  String? responseName;
  String? response;

  /// The BER type for the extended response value element.
  static const int TYPE_EXTENDED_RESPONSE_VALUE = 0x8B;

  ExtendedResponse(LDAPMessage m) : super(m) {
    if( m.elements.length >= 3) {
      responseName = _elementAsString(m.elements[2]);
    }
    // check for optional response
    if (m.elements.length >= 4) {
      response = _elementAsString(m.elements[3]);
    }
  }

  String _elementAsString(ASN1Object _obj) {
    var octets = ASN1OctetString.fromBytes(_obj.encodedBytes);
    return octets.stringValue;
  }
}
