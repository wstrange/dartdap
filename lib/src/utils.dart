import 'dart:convert';

/// Escape non-ASCII characters to create a string that is valid for use in filters
/// DNs, etc.
String escapeNonAscii(String input, {bool escapeParentheses = false}) {
  StringBuffer escaped = StringBuffer();
  for (int codeUnit in utf8.encode(input)) {
    if (codeUnit > 127) {
      escaped.write(r'\');
      escaped.write(codeUnit.toRadixString(16).toLowerCase().padLeft(2, '0'));
    } else {
      escaped.write(String.fromCharCode(codeUnit));
    }
  }
  if (escapeParentheses) {
    return escaped.toString().replaceAll('(', r'\28').replaceAll(')', r'\29');
  }

  return escaped.toString();
}

/// A utility to escape the input string to make it safe for LDAP filters
/// Note this is not correct for all cases. It leaves the
/// leading and trailing parens alone as they are part of the filter.
/// It assumes embedded parens are escaped - which might not be what you want.
///
///
/// It is strongly suggested to use programmatic filters instead of the query() function
/// If you really want to use query() you should carefully escape the input string
/// in your code before passing it to query().  This will break for things
/// like DNs that use special characters in the DN.
String escapeSpecialCharsInLdapFilter(String value) {
  // final specialChars = ['*', '\\'];

  // todo: hack to ignore first and last parens
  var escapedValue = '';
  for (var i = 1; i < value.length - 1; i++) {
    final char = value[i];
    escapedValue += switch (char) {
      '*' => r'\*',
      '(' => r'\28',
      ')' => r'\29',
      // '\\' => r'\\',
      // ' ' => r'\20',
      _ => char,
    };
  }
  return '($escapedValue)';
}
