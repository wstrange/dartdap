library attribute;

/**
 * Represents an LDAP Attribute
 */
class Attribute {
  String _name;
  Set _values = new Set();

  String get name => _name;

  Set get values => _values;

  Attribute(this._name,dynamic v) {
   if( v is Iterable )
     _values.addAll(v);
   else
      _values.add(v);
  }

  addValue(dynamic val) => _values.add(val);

  String toString() => "A(${_name}, ${_values})";

  // two attributes are equal if they have the same name
  // and contain the same set of values.
  bool operator ==(Attribute other) => (_name == other._name) &&
            _values.containsAll(other._values) &&
            other._values.containsAll(_values);
}

/**
 * A set of attributes
 */
class Attributes {
  Map<String,Attribute> _attributes;


  Iterable<Attribute> get attributes => _attributes.values;

  addAttribute(Attribute a) => _attributes[a.name] = a;

  Attributes(this._attributes);

  /**
   * Convert map [m] consisting of possibly simple string or list values
   * to a map that contains only [Attribute] values.
   */
  static Map<String,Attribute> fromMap(Map <String,dynamic> m) {
     var newmap = new Map<String,Attribute>();
     m.forEach( (k,v) {
       // todo: test v to see if it is an attribute type?/
      if( v is Attribute)
        newmap[k] = v;
      else
       newmap[k] = new Attribute(k,v);
     });
     return newmap;
  }

}