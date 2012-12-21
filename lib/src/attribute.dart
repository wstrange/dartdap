library attribute;

/**
 * Represents an LDAP Attribute
 */
class Attribute {
  String _name;
  Set<String> _values = new Set<String>();

  String get name => _name;

  Set<String> get values => _values;

  Attribute(this._name);

  Attribute.collection(this._name, Iterable c) {
    _values.addAll(c);
  }

  Attribute.simple(this._name, String v) {
    _values.add(v);
  }

  addValue(String val) => _values.add(val);


  String toString() => "Attr(${_name}, ${_values})";
}
