import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';

/// See https://ldap.com/ldap-dns-and-rdns/ for rules for DNs / RDNs
///
/// TODO: Place holder for supporting RDN handling...

const equalsChar = 0x3d;

class RDN {
  final ASN1OctetString attributeName;
  // The attribute value should hold the escaped value
  final ASN1OctetString attributeValue;

  RDN(this.attributeName, this.attributeValue);

  ASN1OctetString get asn1OctetString {
    var x = Uint8List(attributeName.octets.length + attributeValue.octets.length + 1);

    x.setRange(0, attributeName.octets.length, attributeName.octets);
    x[attributeName.octets.length] = equalsChar;
    x.setRange(attributeName.octets.length + 1, x.length, attributeValue.octets);

    return ASN1OctetString(x);
  }

  static RDN fromString(String rdn) {
    var x = rdn.split('=');
    if (x.length != 2) {
      throw Exception('Invalid RDN: $rdn');
    }

    return RDN(_escape(x[0]), _escape(x[1]));
  }

  static RDN fromNameValue(String name, String value) {
    return RDN(_escape(name), _escape(value));
  }

  static ASN1OctetString _escape(String s) {
    return ASN1OctetString(utf8.encode(escapeRDNValue(s)));
  }

  // Prints this RDN as a Dart String (utf-16).
  @override
  String toString() => utf8.decode(asn1OctetString.octets);
}

String escapeRDNValue(String value) {
  final buffer = StringBuffer();
  for (int i = 0; i < value.length; i++) {
    final char = value[i];
    switch (char) {
      case ',':
        buffer.write('\\,');
        break;
      case '+':
        buffer.write('\\+');
        break;
      case '"':
        buffer.write('\\"');
        break;
      case '\\':
        buffer.write('\\\\');
        break;
      case '<':
        buffer.write('\\<');
        break;
      case '>':
        buffer.write('\\>');
        break;
      case ';':
        buffer.write('\\;');
        break;
      case '=':
        buffer.write('\\=');
        break;
      case '#':
        if (i == 0) {
          buffer.write('\\#');
        } else {
          buffer.write(char);
        }
        break;
      case ' ':
        if (i == 0 || i == value.length - 1) {
          buffer.write('\\ ');
        } else {
          buffer.write(char);
        }
        break;
      default:
        buffer.write(char);
    }
  }
  return buffer.toString();
}
