
part of ldap_protocol;


class SearchResult {
  
  LDAPResult ldapResult;
  
  
  List<SearchResultEntry> _entries = new List();
  
  add(SearchResultEntry r) => _entries.add(r);
  
  
  String toString() {
    return _entries.toString();
  }
  
}


