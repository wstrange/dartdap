import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:dartdap/dartdap.dart';

const commaChar = 0x2c;

/// Utility for building DNs
/// TOOD: Add DN validity checking. (see RFC 4514)
/// TODO: Add DN escaping
/// TODO: Change API to use DNs instead of Strings
/// // See https://github.com/pingidentity/ldapsdk/issues/10
/// // "The syntax for escaping filters is different from the syntax for escaping DNs. "
///
///
/// TODO: should be immutable, No need to return RDNs.
class DN {
  final ASN1OctetString _asn1OctetString;

  DN(String dn) : _asn1OctetString = _toOctetString(parseDN(dn));

  ASN1OctetString get octetString => _asn1OctetString;

  // Append [second[] DN to the [first] DN and return a new DN.
  static DN join(DN first, DN second) {
    var a = first.octetString;
    var b = second.octetString;
    var x = Uint8List(a.octets.length + b.octets.length + 1);
    x.setRange(0, a.octets.length, a.octets);
    x[a.octets.length] = commaChar;
    x.setRange(a.octets.length + 1, x.length, b.octets);
    return DN.fromOctetString(ASN1OctetString(x));
  }

  // Convenience method to join two DNs
  DN operator +(DN other) => join(this, other);

  // Create a DN from an ASN1OctetString. This is used when decoding a DN from a search result
  DN.fromOctetString(ASN1OctetString t) : _asn1OctetString = t;

  get isEmpty => _asn1OctetString.utf8StringValue.isEmpty;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DN && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => _asn1OctetString.utf8StringValue;
}

// Given a DN string, return a list of RDNs
// The RDNs will have the attribute values escaped
List<RDN> parseDN(String dn) {
  // todo: This is not correct, and does handle escaped commas
  if (dn.isEmpty) {
    return [];
  }
  var rdnStrings = dn.split(',');
  if (rdnStrings.isEmpty) {
    throw Exception('Invalid DN: $dn');
  }
  return rdnStrings.map((rdn) => RDN.fromString(rdn)).toList();
}

ASN1OctetString _toOctetString(List<RDN> rdns) {
  var b = BytesBuilder();
  for (int i = 0; i < rdns.length; i++) {
    b.add(rdns[i].asn1OctetString.octets);
    if (i < rdns.length - 1) {
      b.addByte(commaChar);
    }
  }
  var asn1OctetString = ASN1OctetString(Uint8List.fromList(b.toBytes()));
  return asn1OctetString;
}
