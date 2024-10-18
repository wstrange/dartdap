/// Utility for building DNs
/// TOOD: Add DN validity checking. (see RFC 4514)
/// TODO: Add DN escaping
/// TODO: Change API to use DNs instead of Strings
class DN {
  final String _dn;

  const DN(this._dn);

  DN concat(String prefix) => DN('$prefix,$_dn');

  String get dn => _dn.toString();

  get isEmpty => null;

  @override
  String toString() => _dn;
}
