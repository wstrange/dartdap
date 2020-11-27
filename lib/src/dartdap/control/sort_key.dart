///
///
/// Description taken from OpenDJ SDK!!!
///
///
/// A search result sort key as defined in RFC 2891 is used to specify how search
/// result entries should be ordered. Sort keys are used with the server side
/// sort request control
/// {@link org.forgerock.opendj.ldap.controls.ServerSideSortRequestControl}, but
/// could also be used for performing client side sorting as well.
/// <p>
/// The following example illustrates how a single sort key may be used to sort
/// entries as they are returned from a search operation using the {@code cn}
/// attribute as the sort key:
///
/// <pre>
/// Connection connection = ...;
/// SearchRequest request = ...;
///
/// Comparator&lt;Entry> comparator = SortKey.comparator('cn');
/// Set&lt;SearchResultEntry>; results = TreeSet&lt;SearchResultEntry>(comparator);
///
/// connection.search(request, results);
/// </pre>
///
/// A sort key includes an attribute description and a boolean value that
/// indicates whether the sort should be ascending or descending. It may also
/// contain a specific ordering matching rule that should be used for the sorting
/// process, although if none is provided it will use the default ordering
/// matching rule for the attribute type.
///
///[RFC 2891 - LDAP Control
///      Extension for Server Side Sorting of Search Results| 'http:tools.ietf.org/html/rfc2891']

class SortKey {
  bool isReverseOrder;

  // The name  or the OID of the matching rule, if specified,
  // which should be used when comparing attributes using this sort key.
  // if null a default matching rule will be used by the server
  String? orderMatchingRule;
  // the name of the attributed to be sorted using this sort key
  String attributeDescription;

  SortKey(this.attributeDescription,
      [this.orderMatchingRule, this.isReverseOrder = false]);

  @override
  String toString() =>
      'SortKey($attributeDescription,isreverse=$isReverseOrder,matchingRule:$orderMatchingRule)';
}
