import 'dart:convert';

/// Escape non-ASCII characters to create a string that is valid for use in filters
/// DNs, etc.
String escapeNonAscii(String input, {bool escapeParentheses = false}) {
  StringBuffer escaped = StringBuffer();
  for (int codeUnit in utf8.encode(input)) {
    if (codeUnit > 127) {
      escaped.write(r'\');
      escaped.write(codeUnit.toRadixString(16).toUpperCase().padLeft(2, '0'));
    } else {
      escaped.write(String.fromCharCode(codeUnit));
    }
  }
  if (escapeParentheses) {
    return escaped.toString().replaceAll('(', r'\28').replaceAll(')', r'\29');
  }

  return escaped.toString();
}
