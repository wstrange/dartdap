
part of ldap_protocol;

class LDAPException implements Exception {
  
  String _message;
  
  get message => _message;
  
  LDAPException(this._message);
  
  String toString() => "LDAPException(${message}})";
  
}
