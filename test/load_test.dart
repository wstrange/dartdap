import 'package:unittest/unittest.dart';
import 'package:dartdap/ldap_client.dart';

import 'dart:math';
import 'dart:isolate';
import 'dart:async';

const int NUM_ENTRIES = 50;

typedef Future LdapFun(int i, LDAPConnection ldap);

// calls an ldap function N times.
// This is used to syncronize and chain multiple future calls.
// TODO: Find a more elegant way of doing this. This is ugly
Future repeatNtimes(int i, LDAPConnection ldap, LdapFun fun) {
  if(  i <= 1)
    return new Future.value(null);

  return fun(i,ldap).then( (r) {
    logMessage("result=${r}");
    return repeatNtimes(i-1,ldap,fun);
   },
    onError: (e) {
      logMessage("Error result - ignored ${e}");
      return  repeatNtimes(i-1,ldap,fun);
  });
}

var dn = new DN("ou=People,dc=example,dc=com");


main() {
  LDAPConnection ldap;
  var ldapConfig = new LDAPConfiguration('ldap.yaml');


  initLogging();

  group('Test group', () {
    setUp( () {
      return ldapConfig.getConnection()
          .then( (LDAPConnection l) => ldap =l );
    });

    tearDown( () {
      return ldapConfig.close();
    });

    test('delete previous entries from last run', () {
      repeatNtimes(NUM_ENTRIES, ldap, (int j,LDAPConnection l) {
        var d = dn.concat("uid=test$j");
        logMessage("delete $j");
        return l.delete(d.dn);
      });
    });

   /**
    * Add a number of entries
    */
   test('bulk add', () {
     repeatNtimes(NUM_ENTRIES, ldap,  (i,ldap) {
       var attrs = { "sn":"test$i", "cn":"Test user$i",
                          "objectclass":["inetorgperson"]};
     return ldap.add("uid=test$i,ou=People,dc=example,dc=com", attrs);});

   });


   test('search for entries', () {
     int count = 0;
     var f = Filter.substring("uid=test*");

     // todo - use listen onDone: to hook in
     return ldap.search("ou=People,dc=example,dc=com",f,["uid","sn"]).
          listen((SearchEntry entry) {
           logMessage("count=${++count} Got entry= ${entry} ");
         });
   });

  }); // end group

}
