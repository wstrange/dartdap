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

// Escape a DN / RDN component
// See https://ldap.com/ldap-dns-and-rdns/

// String escapeRDNvalue(String val, {bool escapeNonAscii = false}) {
//   if (val.isEmpty) return val;

//   final specialChars = r'+<>#;"=\,';
//   final buffer = StringBuffer();
//   // final runes = val.runes.toList();
//   final runes = utf8.encode(val);

//   for (int i = 0; i < runes.length; i++) {
//     final char = String.fromCharCode(runes[i]);
//     // Escape special chars and non-printable ASCII
//     if (specialChars.contains(char) || runes[i] < 32) {
//       buffer.write('\\');
//       // Use hex format for non-printable characters
//       if (runes[i] < 16) {
//         buffer.write('0${runes[i].toRadixString(16)}');
//       } else if (runes[i] < 32) {
//         buffer.write(runes[i].toRadixString(16));
//       } else {
//         buffer.write(char);
//       }
//     } else if (runes[i] > 128 && escapeNonAscii) {
//       buffer.write('\\');
//       buffer.write(runes[i].toRadixString(16).toLowerCase());
//     } else {
//       buffer.write(char);
//     }
//   }

//   String escapedDn = buffer.toString();
//   // Handle leading/trailing spaces and #
//   if (escapedDn.startsWith(' ') || escapedDn.startsWith('#')) {
//     escapedDn = "\\$escapedDn";
//   }
//   if (escapedDn.endsWith(' ')) {
//     escapedDn = '${escapedDn.substring(0, escapedDn.length - 1)}\\ ';
//   }

//   return escapedDn;
// }
