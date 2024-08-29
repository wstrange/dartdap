
/// Utility for building DNs
class DN {
  final String _dn;

  DN(this._dn);

  DN concat(String prefix) => DN('$prefix,$_dn');

  String get dn => _dn.toString();

  @override
  String toString() => _dn;
}

