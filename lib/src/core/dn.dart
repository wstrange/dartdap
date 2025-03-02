import 'package:asn1lib/asn1lib.dart';
import 'package:dartdap/dartdap.dart';

/// Utility for building DNs
/// TOOD: Add DN validity checking. (see RFC 4514)
/// TODO: Add DN escaping
/// TODO: Change API to use DNs instead of Strings
/// // See https://github.com/pingidentity/ldapsdk/issues/10
/// // "The syntax for escaping filters is different from the syntax for escaping DNs. "
class DN {
  // final String _dn;
  final List<RDN> _rdns;

  DN(String dn) : _rdns = parseDN(dn);
  DN.fromRDNs(List<RDN> rdns) : _rdns = rdns;
  DN concat(String prefix) => DN('$prefix,$this');

  ASN1OctetString toOctetString() => ASN1OctetString(toString());

  List<RDN> get rdns => _rdns;

  get isEmpty => _rdns.isEmpty;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DN && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => _rdns.map((rdn) => rdn.toString()).join(',');

  DN.preEscaped(String d) : _rdns = d.split(',').map((rdn) => RDN.fromString(rdn, escape: false)).toList();
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
