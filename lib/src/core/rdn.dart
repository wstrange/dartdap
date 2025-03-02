import '../utils.dart';

/// See https://ldap.com/ldap-dns-and-rdns/ for rules for DNs / RDNs
///
/// TODO: Place holder for supporting RDN handling...

class RDN {
  final String attributeName;
  // The attribute value should hold the escaped value
  final String attributeValue;

  RDN(this.attributeName, String attributeValue) : attributeValue = escapeRDNvalue(attributeValue);

  static RDN fromString(String rdn, {bool escape = true}) {
    var x = rdn.split('=');
    if (x.length != 2) {
      throw Exception('Invalid RDN: $rdn');
    }

    return escape ? RDN(x[0], x[1]) : RDN.preEscaped(x[0], x[1]);
  }

  RDN.preEscaped(this.attributeName, this.attributeValue);

  @override
  String toString() => '$attributeName=$attributeValue';
}
