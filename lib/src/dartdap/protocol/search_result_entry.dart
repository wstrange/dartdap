part of ldap_protocol;

/**
 * LDAP Search Entry represent a single search result item.
 *
 * SearchResultEntry is a protocol Op that wraps a
 * [SearchEntry] object. We do this so that the protocol details
 * are kept out of SearchEntry for library consumers.
 */

class SearchResultEntry extends ResponseOp {
  SearchEntry _searchEntry;

  SearchEntry get searchEntry => _searchEntry;

  SearchResultEntry(LDAPMessage m) : super.searchEntry() {
    var s = m.protocolOp;

    var t = s.elements[0] as ASN1OctetString;

    var dn = t.stringValue;

    loggeRecvLdap.fine("Search Result Entry: dn=${dn}");

    // embedded sequence is attr list
    var seq = s.elements[1] as ASN1Sequence;

    _searchEntry = new SearchEntry(dn);

    seq.elements.forEach((ASN1Sequence attr) {
      var attrName = attr.elements[0] as ASN1OctetString;

      var vals = attr.elements[1] as ASN1Set;
      var valSet =
          vals.elements.map((v) => (v as ASN1OctetString).stringValue).toSet();

      searchEntry.attributes[attrName.stringValue] =
          new Attribute(attrName.stringValue, valSet);

      loggeRecvLdap.finest("attribute: ${attrName.stringValue}=${valSet}");
    });

    // controls are optional.
    if (s.elements.length >= 3) {
      var controls = s.elements[2];
      loggeRecvLdap.finest("controls: ${controls}");
    }
  }

  String toString() {
    return "SearchResultEntry($searchEntry})";
  }
}
