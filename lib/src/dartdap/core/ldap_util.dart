// todo: why a class? Make a top level functions?
class LdapUtil {
  /// Escape an ldap string used in a search filter.
  /// The LDAP spec requires *,),(,\ and null to be escaped.
  ///
  static String escapeString(String s) {
    var buf = StringBuffer();
    for (var c in s.codeUnits) {
      switch (c) {
        case 0x2a: // *
        case 0x28: // )
        case 0x29: // )
        case 0x00: // null
          // Temporary fix for https://github.com/wstrange/dartdap/issues/60
          // case 0x5c: // \
          buf.write('\\');
          buf.write(c.toRadixString(16));
          break;
        default:
          buf.writeCharCode(c);
          break;
      }
    }

    return buf.toString();
  }

  /// Convert a list of bytes to a hex string with
  /// each byte separated by a space
  static String toHexString(List<int> bytes) {
    var buf = StringBuffer();

    for (var b in bytes) {
      buf.write(b.toRadixString(16));
      buf.write(' ');
    }
    return buf.toString();
  }
}
