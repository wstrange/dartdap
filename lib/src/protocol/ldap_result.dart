part of ldap_protocol;


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
    
  }
}
