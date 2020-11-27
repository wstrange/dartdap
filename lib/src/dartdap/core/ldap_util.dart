// todo: why a class? Make a top level functions?
class LdapUtil {
  /// Escape an ldap string used in a search filter.
  /// The LDAP spec requires *,),(,\ and null to be escaped.
  ///
  static String escapeString(String s) {
    var buf = StringBuffer();
    s.codeUnits.forEach((c) {
      switch (c) {
        case 0x2a: // *
        case 0x28: // )
        case 0x29: // )
        case 0x00: // null
        case 0x5c: // \
          buf.write('\\');
          buf.write(c.toRadixString(16));
          break;
        default:
          buf.writeCharCode(c);
          break;
      }
    });

    return buf.toString();
  }

  /// Convert a list of bytes to a hex string with
  /// each byte seperated by a space
  static String toHexString(List<int> bytes) {
    var buf = StringBuffer();

    bytes.forEach((b) {
      buf.write(b.toRadixString(16));
      buf.write(' ');
    });
    return buf.toString();
  }
}

/// Utility for building DN's
class DN {
  final String _dn;

  DN(this._dn);

  DN concat(String prefix) => DN('$prefix,$_dn');

  String get dn => _dn.toString();

  @override
  String toString() => _dn;
}
