part of ldap_protocol;


class ResponseHandler {
  LDAPMessage _ldapMessage;

  ResponseHandler(this._ldapMessage);

  static ProtocolOp handleResponse(LDAPMessage m) {

    var p = m.protocolOp;
    logger.finest("handle response tag=${_op2String(p.tag)}");

    ProtocolOp op;
    switch(p.tag) {
      case BIND_RESPONSE:
        return new BindResponse(p);

      case SEARCH_RESULT_ENTRY:
        return new SearchResultEntry(p);

      case SEARCH_RESULT_DONE:
        return new SearchResultDone(p);

      case EXTENDED_RESPONSE:
         return new ExtendedResponse(p);


      case ADD_RESPONSE:
      case DELETE_RESPONSE:
      case MODIFY_RESPONSE:
      case MODIFY_DN_RESPONSE:
      case COMPARE_RESPONSE:
        return new GenericResponse(p);


      default:
        throw "Not done";
    }
    return op;

  }
}
