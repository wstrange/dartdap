
part of ldap_protocol;


class SearchResult {
  
  List<SearchEntryResponse> _entries = new List();
  
  add(SearchEntryResponse r) => _entries.add(r);
  
}


