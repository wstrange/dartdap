part of ldap_protocol;


class Attribute {
  String _name;
  
  Set<String> _values = new Set<String>();
  
  String get name => _name;
  
  Set<String> get values => _values; 
  
  Attribute(this._name, this._values);
  
  addValue(String val) {
    _values.add(val);
  }
  
  Attribute.fromASN1(ASN1OctetString name, ASN1Set vals) {
    _name = name.stringValue;
    vals.elements.forEach( (v) { 
      var s = v as ASN1OctetString;
      _values.add(s.stringValue); 
     });
  }
  
  String toString() => "Attr(${_name}, ${_values})";
}
