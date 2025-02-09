import 'dart:convert';

/// Escape non-ASCII characters to create a string that is valid for use in filters
/// DNs, etc.
String escapeNonAscii(String input) {
  StringBuffer escaped = StringBuffer();
  for (int codeUnit in utf8.encode(input)) {
    if (codeUnit > 127) {
      escaped.write(r'\');
      escaped.write(codeUnit.toRadixString(16).toUpperCase().padLeft(2, '0'));
    } else {
      escaped.write(String.fromCharCode(codeUnit));
    }
  }
  return escaped.toString();
}
