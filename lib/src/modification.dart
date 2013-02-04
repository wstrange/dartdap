library modification;

class Modification {
  const int ADD = 0;
  const int DELETE = 1;
  const int REPLACE = 2;
  const int INCREMENT = 3;

  String _attrName;

  // attr values
  List _values = new List();

  int _operation;

  String get attributeName => _attrName;
  int get operation => _operation;
  List get values => _values;

  Modification(this._operation, this._attrName, this._values);

  Modification.replace(this._attrName, this._values ) {
    _operation = REPLACE;
  }

}
