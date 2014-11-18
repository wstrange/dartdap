library attribute;

/**
 * Represents an LDAP Attribute
 */
class Attribute {
  String _name;
  Set _values = new Set();

  String get name => _name;

  Set get values => _values;

  Attribute(this._name, dynamic v) {
    if (v is Iterable) {
      _values.addAll(v);
    } else {
      _values.add(v);
    }
  }

  addValue(dynamic val) => _values.add(val);

  // note that when printed in a map, the attr name will be printed - so
  // we just print the value
  String toString() => "$_values";

  // two attributes are equal if they have the same name
  // and contain the same set of values.
  bool operator ==(Attribute other) => (_name == other._name) && _values.containsAll(other._values) && other._values.containsAll(_values);


  //  Convenience method to convert map [m] consisting of possibly simple string or list values
  //  to a map that contains only [Attribute] values.
  // This lets you write more "darty" code consisting of plain maps
  static Map<String, Attribute> newAttributeMap(Map<String, dynamic> m) {
    var newmap = new Map<String, Attribute>();
    m.forEach((k, v) {
      newmap[k] = (v is Attribute ? v : new Attribute(k,v));
    });
    return newmap;
  }
}
