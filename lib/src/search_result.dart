library search_result;

import 'dart:async';
import 'control/control.dart';
import 'ldap_result.dart';

///
/// Results from a search request
/// Provides a handle to listen stream for search results
/// provides VLV context info - for example to pass on to a subsequent search
/// Is this the right design?
///

class SearchResult {
  LDAPResult ldapResult;

  SearchResult(this._stream);

  // Stream of search entries
  //  listen using  stream.listen( (SearchResultEntry entry) =>  dosomething));
  Stream<SearchEntry> _stream;

  Stream<SearchEntry> get stream => _stream;

  // The controls that may have been returned on search completion
  // These can be used to obtain the cursor, number of remaing results, etc. for VLV search
  List<Control> controls;
}