
library ldap_util;


class LDAPUtil {


  /**
   * Escape an ldap string used in a search filter.
   * The LDAP spec requires *,),(,\ and null to be escaped.
   *
   */
  static String escapeString(String s) {
    StringBuffer buf = new StringBuffer();
    s.charCodes.forEach( (c) {

      switch(c) {
      	case 0x2a:  // *
      	case 0x28:  // )
      	case 0x29:  // )
      	case 0x00:  // null
      	case 0x5c: // \
          buf.add('\\');
          buf.add(c.toRadixString(16));
          break;
        default:
          buf.addCharCode(c);
          break;
      }

    });

    return buf.toString();
  }

  /**
   * Convert a list of bytes to a hex string with
   * each byte seperated by a space
   */
  static String toHexString(List<int> bytes) {
    var buf = new StringBuffer();

    bytes.forEach( (b) {
      buf.add(b.toRadixString(16));
      buf.add(' '); });
    return buf.toString();
  }
}
