part of ldap_protocol;


class ResponseHandler {
  LDAPMessage _ldapMessage;

  ResponseHandler(this._ldapMessage);

  static ResponseOp handleResponse(LDAPMessage m) {

    loggeRecvLdap.finer("LDAP response received: ${_op2String(m.protocolOp.tag)}");

    ResponseOp op;
    switch(m.protocolOp.tag) {
      case BIND_RESPONSE:
        return new BindResponse(m);

      case SEARCH_RESULT_ENTRY:
        return new SearchResultEntry(m);

      case SEARCH_RESULT_DONE:
        return new SearchResultDone(m);

      case EXTENDED_RESPONSE:
         return new ExtendedResponse(m);


      case ADD_RESPONSE:
      case DELETE_RESPONSE:
      case MODIFY_RESPONSE:
      case MODIFY_DN_RESPONSE:
      case COMPARE_RESPONSE:
        return new GenericResponse(m);


      default:
        throw "Not done";
    }
    return op;

  }
}
