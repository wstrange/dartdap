part of ldap_protocol;


class Attribute {
  String _name;
  
  List<String> _values = new List<String>();
  
  String get name => _name;
  
  Attribute(this._name, this._values);
  
  
  addValue(String val) {
    _values.add(val);
  }
}
