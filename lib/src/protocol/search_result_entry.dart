part of 'ldap_protocol.dart';

/// LDAP Search Entry represent a single search result item.
///
/// SearchResultEntry is a protocol Op that wraps a
/// [SearchEntry] object. We do this so that the protocol details
/// are kept out of SearchEntry for library consumers.

class SearchResultEntry extends ResponseOp {
  late SearchEntry _searchEntry;

  SearchEntry get searchEntry => _searchEntry;

  SearchResultEntry.referral(LDAPMessage m) : super.searchEntry() {
    loggerRecvLdap.fine(() => 'Search result is a referral');
    var uris = m.protocolOp.elements;
    var l = uris.map((obj) => (obj as ASN1OctetString).stringValue).toList();
    _searchEntry = SearchEntry(DN(''), referrals: l);
  }

  // Creates an entry for a single result. Note that
  // This is not like most ResponseOps - in that it does
  // not have an LDAPResult object. The result
  // only comes at the end with the SearchResultDone message
  SearchResultEntry(LDAPMessage m) : super.searchEntry() {
    var s = m.protocolOp;

    var t = s.elements[0] as ASN1OctetString;

    var dn = DN.fromOctetString(t);

    loggerRecvLdap.fine(() => 'Search Result Entry: dn=$dn');

    // embedded sequence is attr list
    var seq = s.elements[1] as ASN1Sequence;

    _searchEntry = SearchEntry(dn);

    for (var attr in seq.elements) {
      var a = attr as ASN1Sequence;
      var attrName = a.elements[0] as ASN1OctetString;

      var vals = a.elements[1] as ASN1Set;
      var valSet = vals.elements.map((v) => v).toSet();

      searchEntry.attributes[attrName.utf8StringValue] = Attribute(attrName.utf8StringValue, valSet);

      // TODO: For #69 printing the string values is throwin a utf8 error
      // if the value is not a utf-8 string.  Create a safe print option
      // loggerRecvLdap.finest('attribute: ${attrName.stringValue}=$valSet');
      loggerRecvLdap.finest('attribute: ${attrName.stringValue}');
    }

    // controls are optional.
    if (s.elements.length >= 3) {
      var controls = s.elements[2];
      loggerRecvLdap.finest('controls: $controls');
    }
  }

  @override
  String toString() {
    return 'SearchResultEntry($searchEntry})';
  }
}
