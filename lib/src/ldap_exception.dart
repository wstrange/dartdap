
library ldap_exception;

import 'ldap_result.dart';

class LDAPException implements Exception {

  String _message;

  LDAPResult _ldapResult;

  String get message => _message;
  LDAPResult get ldapResult => _ldapResult;

  LDAPException(this._message,[this._ldapResult]);

  String toString() => "LDAPException(${message}, result=${_ldapResult})";

}

// Used for Non zero LDAP Result codes
class LDAPResultException extends LDAPException {
  LDAPResultException(LDAPResult r):super("LDAP Result error", r) {

  }
}
