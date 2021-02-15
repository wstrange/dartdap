import 'dart:async';

import 'ldap_result.dart';
import '../control/control.dart';

/// Results from a search request.
///
/// This object is produced by the [LdapConnection.search] method.
///
/// Use the [stream] property to get a stream of [SearchEntry] objects, which
/// represents the results from the search operation.
///
/// The [controls] property contains the VLV context information, for example
/// to pass on to a subsequent search.
///

// TODO: Is this the right design?

class SearchResult {
  // todo: The result should be a function Future<LdapResult>
  // That only completes when the search is finished..
  //late LdapResult _ldapResult;
  List<Control> _controls = [];

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
  final Stream<SearchEntry> _stream;

  final Completer<LdapResult> _resultCompleter = Completer();

  Future<LdapResult> getLdapResult() {
    return _resultCompleter.future;
  }

  // Complete the ldap result. This causes the future to return with the
  // ldap result.
  void completeLdapResult(LdapResult r) {
    ///_ldapResult = r;
    _resultCompleter.complete(r);
  }

  /// The controls that may have been returned on search completion.
  ///
  /// These can be used to obtain the cursor, number of remaining results, etc. for VLV search.

  // TODO: This needs to be a stream...
  set controls(List<Control> s) => _controls = s;
  // Trying to read a control before the stream has been processed is an error
  List<Control>  get controls {
    return _controls;
  }
}
