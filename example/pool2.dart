import 'dart:async';

import 'package:dartdap/dartdap.dart';
import 'package:logging/logging.dart';

// final adminPassword = 'SomePassword';
final adminPassword = 'gkwBPFz1W6Owr3Yy7CwfFFLCFpI8hPHi';

/// Integration test to debug the connection pool.
/// This is a work in progress...
///
Future<void> main() async {
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}: ${r.loggerName}: ${r.level.name}: ${r.message}');
  });

  Logger.root.level = Level.INFO;
  await example();
}

Future<void> example() async {
  // Create a prototype connection
  var connection =
      LdapConnection(port: 1389, bindDN: 'uid=admin', password: adminPassword);
  // The pool is created from the connection. The pool implements the Ldap Interface
  var adminPool = LdapConnectionPool(connection);
  var userPool = LdapConnectionPool(connection);

  await adminSearchAndBind(adminPool,userPool);

}

// search as the admin user
Future<void> adminSearchAndBind(LdapConnectionPool adminPool,LdapConnectionPool userPool) async {
  var filter = Filter.equals('objectClass', 'inetorgperson');

  for(int i=0; i < 10; ++i) {
    try {

      // Search for some users
      var searchResult = await adminPool
          .search('ou=people,ou=identities', filter, ['dn','uid'], sizeLimit: 10);

      await bindUsers(searchResult,userPool);
      await Future.delayed(Duration(seconds: 10));

    } catch (e) {
      print('Exception --->$e  ${e.runtimeType}');
    }
  }
}

final TEST_PASSWORD = 'Bar1Foo2';


// Given search results - try to bind each user.
Future<void> bindUsers(SearchResult searchResult,LdapConnectionPool p) async {
  var result = await searchResult.getLdapResult();
  print('got result = $result');
  if (result.resultCode == ResultCode.OK ||
      result.resultCode == ResultCode.SIZE_LIMIT_EXCEEDED) {
    await for(var entry in searchResult.stream) {
      print('Bind dn ${entry.dn}');
      try {
        var r2 = await p.bind(DN: entry.dn, password: TEST_PASSWORD);
        print('bind result ${r2.resultCode} ${r2}');
      }
      on LdapResultInvalidCredentialsException catch(e) {
        print('Invalid credentials for ${entry.dn}');
      }
      catch(e,st) {
        print('Exception when binding $e');
        print('st=$st');
      }
      finally {
        //await p.close();
      }
    }
  } else {
    print('ldap error ${result.resultCode}');
  }
}
