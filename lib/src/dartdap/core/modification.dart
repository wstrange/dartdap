/// An LDAP modification operation type.
///
/// [ADD] adds a new value to an attribute.
/// [DELETE] deletes a value from an attribute or delete the attribute
/// [REPLACE] replaces an attribute value with a new value
/// [INCREMENT] increments a numeric attribute value
///

class Modification {
  static const int ADD = 0;
  static const int DELETE = 1;
  static const int REPLACE = 2;
  static const int INCREMENT = 3;

  final String _attrName;

  // attr values
  final List _values;

  final int _operation;

  String get attributeName => _attrName;
  int get operation => _operation;
  List get values => _values;

  Modification(this._operation, this._attrName, this._values);

  Modification.replace(this._attrName, this._values) : _operation = REPLACE;

  Modification.add(this._attrName, this._values) : _operation = ADD;

  Modification.increment(this._attrName, this._values) : _operation = INCREMENT;

  Modification.delete(this._attrName, this._values) : _operation = DELETE;

  ///
  /// TODO: This is a hack. Create a nicer way of handling this
  ///
  /// Utility method that creates a list of modifications
  /// when given a [modList] of triplets consisting of
  /// modType - string value in the set `[a,d,r,i]`
  ///    (for add, delete, replace, increment)
  /// followed by attribute,values
  ///
  /// For example, the list
  /// ```
  /// ['r','sn', 'Mickey Mouse','i', 'age',null]
  /// ```
  /// replaces the sn attribute with Mickey Mouse, and increments the
  /// age attribute by one.
  ///
  static List<Modification> modList(List modList) {
    var list = <Modification>[];
    for (var x in modList) {
      assert(x.length == 3);
      String op = x[0];
      var attr = x[1];
      var vals = x[2];
      if (vals is! List) vals = [vals];

      switch (op) {
        case 'a':
          list.add(Modification.add(attr, vals));
          break;
        case 'd':
          list.add(Modification.delete(attr, vals));
          break;
        case 'r':
          list.add(Modification.replace(attr, vals));
          break;
        case 'i':
          list.add(Modification.increment(attr, vals));
          break;
      }
    }
    return list;
  }
}
