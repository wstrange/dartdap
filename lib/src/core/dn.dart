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
  // final String _dn;
  final List<RDN> _rdns;
  ASN1OctetString? _asn1OctetString;

  DN(String dn) : _rdns = parseDN(dn);
  DN.fromRDNs(List<RDN> rdns) : _rdns = rdns;
  // Need to concat an RDN, not a string.
  DN concat(String prefix) => DN('$prefix,$this');

  // Create a DN from an ASN1OctetString. This is used when decoding a DN from a search result
  DN.fromOctetString(ASN1OctetString t) : _rdns = [] {
    _asn1OctetString = t;
  }

  ASN1OctetString toOctetString() {
    if (_asn1OctetString != null) {
      return _asn1OctetString!;
    }

    var b = BytesBuilder();
    for (int i = 0; i < _rdns.length; i++) {
      b.add(_rdns[i].asn1OctetString.octets);
      if (i < _rdns.length - 1) {
        b.addByte(commaChar);
      }
    }
    _asn1OctetString = ASN1OctetString(Uint8List.fromList(b.toBytes()));
    return _asn1OctetString!;
  }

  List<RDN> get rdns => _rdns;

  get isEmpty => _rdns.isEmpty && _asn1OctetString == null;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DN && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => _asn1OctetString?.utf8StringValue ?? _rdns.map((rdn) => rdn.toString()).join(',');
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
