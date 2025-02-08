import 'package:dartdap/dartdap.dart';

// parser that Create LDAP Queries using https://tools.ietf.org/html/rfc2254 syntax

/// The Ldap Interface https://tools.ietf.org/html/rfc4511
///
/// The available LDAP operations are:
///
/// - [bind] - performs a bind with the current authentication or an anonymous bind
/// - [search] - queries the LDAP directory for entries
/// - [compare] - compares values in LDAP entries
/// - [add] - creates a LDAP entry
/// - [delete] - removes an existing LDAP entry
/// - [modify] - changes attributes in an LDAP entry
/// - [modifyDN] - moves an LDAP entry
abstract class Ldap {
  /// Standard port for LDAP (i.e. without TLS/SSL).
  static const PORT_LDAP = 389;

  /// Standard port for LDAP over TLS/SSL.
  static const PORT_LDAPS = 636;

  /// Performs an LDAP add operation.
  ///
  /// [dn] is the LDAP Distinguised Name.
  /// [attrs] is a map of attributes keyed by the attribute name. The
  ///  attribute values can be simple Strings, lists of strings,
  ///or alternatively can be of type [Attribute]
  ///
  /// ## Some possible exceptions
  ///
  /// [LdapResultEntryAlreadyExistsException] thrown when the entry to add
  /// already exists.
  Future<LdapResult> add(DN dn, Map<String, dynamic> attrs);

  //----------------------------------------------------------------
  /// Performs an LDAP BIND operation.
  ///
  /// Sends a bind request using the credentials that were set by
  /// the constructor or passed in via [dn] and [password]. If DN or
  /// password are provided, the values are saved for future bind
  /// operations.
  ///
  /// Returns a Future containing the result of the BIND operation.
  Future<LdapResult> bind({DN? dn, String? password});

  //----------------------------------------------------------------
  /// Performs an LDAP compare operation.
  ///
  /// On the LDAP entry identifyed by the distinguished name [dn],
  /// compare the [attrName] and [attrValue] to see if they are the same.
  ///
  /// The completed [LdapResult] will have a value of [ResultCode.COMPARE_TRUE]
  /// or [ResultCode.COMPARE_FALSE].
  Future<LdapResult> compare(DN dn, String attrName, String attrValue);
  //----------------------------------------------------------------
  /// Performs an LDAP delete operation.
  ///
  /// Delete the LDAP entry identified by the distinguished name in [dn].
  ///
  /// ## Some possible exceptions
  ///
  /// [LdapResultNoSuchObjectException] thrown when the entry to delete did
  /// not exist.
  Future<LdapResult> delete(DN dn);

  //----------------------------------------------------------------
  /// Performs an LDAP modify operation.
  ///
  /// Modifies the LDAP entry [dn] with the list of modifications [mods].
  ///
  /// ## Some possible exceptions
  ///
  /// [LdapResultObjectClassViolationException] thrown when the change would
  /// cause the entry to violate LDAP schema rules.
  Future<LdapResult> modify(DN dn, List<Modification> mods);

  //----------------------------------------------------------------
  /// Performs an LDAP modifyDN operation.
  ///
  /// Modify the LDAP entry identified by [dn] to a new relative [rdn].
  /// If [deleteOldRDN] is true delete the old entry.
  /// If [newSuperior] is not null, re-parent the entry.
  Future<LdapResult> modifyDN(DN dn, DN rdn,
      {bool deleteOldRDN = true, DN? newSuperior});

  //----------------------------------------------------------------
  /// Performs an LDAP search operation.
  ///
  /// Searches for LDAP entries, starting at the [baseDN],
  /// specified by the search [filter], and obtains the listed [attributes].
  ///
  /// The [scope] of the search defaults to SUB_LEVEL (i.e.
  /// search at base DN and all objects below it) if it is not provided.
  ///
  /// The [sizeLimit] defaults to 0 (i.e. no limit).
  ///
  /// An optional list of [controls] can also be provided.
  ///
  /// Example:
  /// ```
  ///     var base = 'dc=example,dc=com';
  ///     var filter = Filter.present('objectClass');
  ///     var attrs = ['dc', 'objectClass'];
  ///
  ///     var sr = await connection.search(base, filter, attrs);
  ///     await for (var entry in sr.stream) {
  ///       // process the entry (SearchEntry)
  ///       // entry.dn = distinguished name (String)
  ///       // entry.attributes = attributes returned (Map<String,Attribute>)
  ///     }
  /// ```
  Future<SearchResult> search(DN baseDN, Filter filter, List<String> attributes,
      {int scope = SearchScope.SUB_LEVEL,
      int sizeLimit = 0,
      List<Control> controls = const <Control>[]});

  /// Like the [search] method, but the filter is constructed using the
  /// [query] string. See https://tools.ietf.org/html/rfc2254
  ///
  Future<SearchResult> query(DN baseDN, String query, List<String> attributes,
      {int scope = SearchScope.SUB_LEVEL,
      int sizeLimit = 0,
      List<Control> controls = const []}) {
    var filter = parseQuery(query);
    return search(baseDN, filter, attributes,
        scope: scope, sizeLimit: sizeLimit, controls: controls);
  }
}
