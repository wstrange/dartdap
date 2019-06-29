/// Represents an LDAP Attribute.
///
/// Use the [name] property to retrieve the attribute's name and
/// the [values] property to retrieve a [Set] of the attribute's values.
///
/// Use the [addValue] method to add another value to the attribute.

class Attribute {
  String _name;
  Set _values = new Set();

  /// The name of the attribute.
  String get name => _name;

  /// The set of values associated with the attribute.
  Set get values => _values;

  /// Constructor.
  ///
  /// Creates an Attribute object and sets its [name] and [values].
  ///
  /// If the [initialValues] is an [Iterable] each of its values are made the
  /// values of the attribute. Otherwise, it is made the single value in
  /// the attribute.

  Attribute(String name, dynamic initialValues) {
    this._name = name;
    if (initialValues is Iterable) {
      _values.addAll(initialValues);
    } else {
      _values.add(initialValues);
    }
  }

  /// Add a value to the existing values in the attribute.

  addValue(dynamic val) => _values.add(val);

  // note that when printed in a map, the attr name will be printed - so
  // we just print the value
  String toString() => "$_values";

  // two attributes are equal if they have the same name
  // and contain the same set of values.
  bool operator ==(Object other) =>
      (other is Attribute &&
          _name == other._name) &&
      _values.containsAll(other._values) &&
      other._values.containsAll(_values);

  /// Converts a map of simple strings or list values into a Map of [Attributes].
  ///
  ///     var attrs = Attribute.newAttributeMap({
  ///       "objectClass" : [ "top", "person", "inetPerson" ],
  ///       "sn": "Smith",
  ///       "cn": "John Smith"
  ///     });
  ///
  /// This is a convenience method to allow code using ordinary Dart [Map]
  /// and [List] to be used to represent attributes, instead of working with
  /// [Set] and LDAP [Attribute] objects.

  static Map<String, Attribute> newAttributeMap(Map<String, dynamic> m) {
    var newmap = new Map<String, Attribute>();
    m.forEach((k, v) {
      newmap[k] = (v is Attribute ? v : new Attribute(k, v));
    });
    return newmap;
  }
}
