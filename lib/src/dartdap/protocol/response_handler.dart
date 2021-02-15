part of ldap_protocol;

abstract class ResponseHandler {
  //LDAPMessage _ldapMessage;
  //ResponseHandler(this._ldapMessage);

  static ResponseOp handleResponse(LDAPMessage m) {
    loggeRecvLdap
        .finer(() => 'LDAP response received: ${_op2String(m.protocolOp.tag)}');

    switch (m.protocolOp.tag) {
      case BIND_RESPONSE:
        return BindResponse(m);

      case SEARCH_RESULT_ENTRY:
        return SearchResultEntry(m);

      case SEARCH_RESULT_REFERENCE:
        return SearchResultEntry.referral(m);

      case SEARCH_RESULT_DONE:
        return SearchResultDone(m);

      case EXTENDED_RESPONSE:
        return ExtendedResponse(m);

      case ADD_RESPONSE:
      case DELETE_RESPONSE:
      case MODIFY_RESPONSE:
      case MODIFY_DN_RESPONSE:
      case COMPARE_RESPONSE:
        return GenericResponse(m);

      default:
        throw 'Not done';
    }
  }
}
