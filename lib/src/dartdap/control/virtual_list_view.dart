import 'control.dart';
import 'package:asn1lib/asn1lib.dart';

/// Virtual List View Controls
/// See [https://tools.ietf.org/html/draft-ietf-ldapext-ldapv3-vlv-09]

/// VLV Request Control. The client sends this to the server to request a VLV search
class VLVRequestControl extends Control {
  static const OID = '2.16.840.1.113730.3.4.9';
  @override
  String get oid => OID;

  // The BER type to use when encoding the byOffset target element.
  static const TYPE_TARGET_BYOFFSET = 0xA0;

  // The BER type to use when encoding the greaterThanOrEqual target element.
  static const TYPE_TARGET_GREATERTHANOREQUAL = 0x81;

  String get controlName => 'VirtualListViewRequestControl';

  int beforeCount;
  int afterCount;

  int offset = 0;
  int contentCount = 100;

  String? assertionValue;
  String? contextId;

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
      {critical = false}) {
    // todo: Sanity checking!!!
    isCritical = critical;
    assertionValue = null;
  }

  VLVRequestControl.newVLVSearch()
      : offset = 0,
        beforeCount = 0,
        afterCount = 100;

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
      {this.contextId, critical = true}) {
    // todo: Sanity checking!!!
    isCritical = critical;
  }

  bool get hasTargetOffset => assertionValue == null;

  @override
  ASN1Sequence toASN1() {
    var s = startSequence();

    var seq = ASN1Sequence();
    seq.add(ASN1Integer.fromInt(beforeCount));
    seq.add(ASN1Integer.fromInt(afterCount));
    if (hasTargetOffset) {
      var s = ASN1Sequence(tag: TYPE_TARGET_BYOFFSET);
      s.add(ASN1Integer.fromInt(offset));
      s.add(ASN1Integer.fromInt(contentCount));
      seq.add(s);
    } else {
      clogger.finest('VLV request Assertion value = $assertionValue');
      seq.add(ASN1OctetString(assertionValue?.codeUnits,
          tag: TYPE_TARGET_GREATERTHANOREQUAL));
    }
    if (contextId != null) seq.add(ASN1OctetString(contextId));

    s.add(ASN1OctetString(seq.encodedBytes));
    return s;
  }
}

class VLVResponseControl extends Control {
  static const OID = '2.16.840.1.113730.3.4.10';
  @override
  String get oid => OID;

  late int targetPosition;
  late int contentCount;
  late int extraParam;

  //List<int> contextID; ????
  //int contextId;

  VLVResponseControl.fromASN1(ASN1OctetString s) {
    var bytes = s.encodedBytes;
    // hack The octet string is actually a sequence. Not
    // sure why ldap does this. Consider moving this to
    // asn1 library.    octetString.unwrapSequence();
    bytes[0] = SEQUENCE_TYPE;
    var seq = ASN1Sequence.fromBytes(bytes);
    clogger.finest('Create control from $s  seq=$seq');

    var x = (seq.elements.first as ASN1Sequence);

    // todo: confirm order of response
    x.elements.forEach((e) => clogger.finest(' ${e.runtimeType}  $e'));
    targetPosition = (x.elements[0] as ASN1Integer).intValue;
    contentCount = (x.elements[1] as ASN1Integer).intValue;
    extraParam = (x.elements[2] as ASN1Integer).intValue;
  }

  @override
  String toString() =>
      '${super.toString()}(targetpos=$targetPosition, contentCount=$contentCount,x=$extraParam)';
}
