import 'ldap_result.dart';
import '../control/control.dart';

/// Results from a search request.
///
/// This object is produced by the [LdapConnection.search] method.
///
/// Use the [stream] property to get a stream of [SearchEntry] objects, which
/// representes the results from the search operation.
///
/// The [controls] property contains the VLV context information, for example
/// to pass on to a subsequent search.
///

// TODO: Is this the right design?

class SearchResult {
  LdapResult ldapResult;
  List<Control> _controls;

  SearchResult(this._stream);

  /// Stream of search entries.
  ///
  /// The stream can be listened to by either:
  ///     await for (SearchEntry entry in searchResult.stream) { doSomething; }
  /// or
  ///     searchResult.stream.listen((SearchEntry entry) =>  doSomething));
  ///
  /// ## Some exceptions
  ///
  /// [LdapResultNoSuchObjectException] thrown when the search finds zero
  /// entries that match.

  Stream<SearchEntry> get stream => _stream;
  Stream<SearchEntry> _stream;

  /// The controls that may have been returned on search completion.
  ///
  /// These can be used to obtain the cursor, number of remaining results, etc. for VLV search.

  // TODO: This needs to be a stream...
  set controls(List<Control> s) => this._controls = s;
  // Trying to read a control before the stream has been processed is an error
  List<Control>  get controls {
    //if( _stream == null || _stream.isEmpty)

    return _controls;
  }
}
