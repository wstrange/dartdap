import '../utils.dart';

/// Utility for building DNs
/// TOOD: Add DN validity checking. (see RFC 4514)
/// TODO: Add DN escaping
/// TODO: Change API to use DNs instead of Strings
class DN {
  final String _dn;

  const DN(this._dn);
  DN concat(String prefix) => DN('$prefix,$_dn');

  String get dn => escapeNonAscii(_dn, escapeParentheses: true);

  get isEmpty => _dn.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DN && runtimeType == other.runtimeType && _dn == other._dn;

  @override
  int get hashCode => _dn.hashCode;

  @override
  String toString() => _dn;
}
