part of dartdap;

/// Virtual List View Controls
/// See [http://www.ietf.org/archive/id/draft-ietf-ldapext-ldapv3-vlv-09.txt]

/// VLV Request Control. The client sends this to the server to request a VLV search
class VLVRequestControl extends Control {
  static const OID = "2.16.840.1.113730.3.4.9";
  String get oid => OID;

  // The BER type to use when encoding the byOffset target element.
  static const TYPE_TARGET_BYOFFSET = 0xA0;

  // The BER type to use when encoding the greaterThanOrEqual target element.
  static const TYPE_TARGET_GREATERTHANOREQUAL = 0x81;

  get controlName => "VirtualListViewRequestControl";

  int beforeCount;
  int afterCount;

  int offset = -1;
  int contentCount = -1;

  //List<int> assertionValue;
  String assertionValue;
  List<int> contextId;

  VLVRequestControl(
      this.beforeCount, this.afterCount, this.offset, this.contentCount);

  /// Creates a new virtual list view request control that will identify the
  /// target entry by a positional offset within the complete result set.
  ///
  ///
  ///
  /// [offset]
  ///            The positional offset of the target entry in the result set,
  ///            where 1 is the first entry.
  ///[contentCount]
  ///        The content count returned by the server in the last virtual
  ///           list view response, or 0 if this is the first virtual
  ///             list view request.
  ///[beforeCount]
  ///         in the search results.
  ///  [afterCount]
  ///           The number of entries after the target entry to be included in
  ///            the search results.
  /// [contextId]
  ///          The context ID provided by the server in the last virtual list
  ///            view response for the same set of criteria, or {@code null} if
  ///           there was no previous virtual list view response or the server
  ///          did not include a context ID in the last response.

  VLVRequestControl.offsetControl(this.offset, this.contentCount,
      this.beforeCount, this.afterCount, this.contextId,
      {critical: false}) {
    // todo: Sanity checking!!!
    isCritical = critical;
    assertionValue = null;
  }

  //
  //  Creates a new virtual list view request control that will identify the
  //  target entry by an assertion value. The assertion value is encoded
  //  according to the ORDERING matching rule for the attribute description in
  //  the sort control. The assertion value is used to determine the target
  //  entry by comparison with the values of the attribute specified as the
  //  primary sort key. The first list entry who's value is no less than (less
  //  than or equal to when the sort order is reversed) the supplied value is
  //  the target entry.

  VLVRequestControl.assertionControl(
      this.assertionValue, this.beforeCount, this.afterCount,
      {this.contextId: null, critical: false}) {
    // todo: Sanity checking!!!
    isCritical = critical;
  }

  bool get hasTargetOffset => assertionValue == null;

  ASN1Sequence toASN1() {
    var s = startSequence();

    var seq = new ASN1Sequence();
    seq.add(new ASN1Integer(beforeCount));
    seq.add(new ASN1Integer(afterCount));
    if (hasTargetOffset) {
      var s = new ASN1Sequence(tag: TYPE_TARGET_BYOFFSET);
      s.add(new ASN1Integer(offset));
      s.add(new ASN1Integer(contentCount));
      seq.add(s);
    } else {
      _clogger.finest("VLV request Assertion value = $assertionValue");
      seq.add(new ASN1OctetString(assertionValue.codeUnits,
          tag: TYPE_TARGET_GREATERTHANOREQUAL));
    }
    if (contextId != null) seq.add(new ASN1OctetString(contextId));

    s.add(new ASN1OctetString(seq.encodedBytes));
    return s;
  }
}

class VLVResponseControl extends Control {
  static const OID = "2.16.840.1.113730.3.4.10";
  get oid => OID;

  int targetPosition;
  int contentCount;
  int extraParam = 0;

  //List<int> contextID; ????
  int contextId;

  VLVResponseControl.fromASN1(ASN1OctetString s) {
    var bytes = s.encodedBytes;
    // hack The octet string is actually a sequence. Not
    // sure why ldap does this. Consider moving this to
    // asn1 library.    octetString.unwrapSequence();
    bytes[0] = SEQUENCE_TYPE;
    var seq = new ASN1Sequence.fromBytes(bytes);
    _clogger.finest("Create control from $s  seq=${seq}");

    var x = (seq.elements.first as ASN1Sequence);

    // todo: confirm order of response
    x.elements.forEach((e) => _clogger.finest(" ${e.runtimeType}  $e"));
    targetPosition = (x.elements[0] as ASN1Integer).intValue;
    contentCount = (x.elements[1] as ASN1Integer).intValue;
    extraParam = (x.elements[2] as ASN1Integer).intValue;
  }

  String toString() =>
      "${super.toString()}(targetpos=$targetPosition, contentCount=$contentCount,x=$extraParam)";
}
