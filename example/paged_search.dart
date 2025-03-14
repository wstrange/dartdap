import 'package:dartdap/dartdap.dart';
import 'package:logging/logging.dart';

/// An example of performing a paged search using the SimplePagedResults Control
/// Tested against ForgeRock DS version 7.0
Future main() async {
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec.message}');
  });

  Logger.root.level = Level.INFO;

  var ldap = LdapConnection(
      host: 'localhost',
      port: 1389,
      ssl: false,
      bindDN: DN('uid=admin'),
      password: 'password');

  var baseDN = DN('dc=example,dc=com');
  var attrs = ['dn', 'uid', 'sn'];
  var pageSize = 100;

  // Create a control that pages through entries 'pageSize' at a time
  var simplePaged = SimplePagedResultsControl(size: pageSize);
  // sort the results based on the 'sn' attribute
  var sss = ServerSideSortRequestControl([SortKey('sn')]);

  var done = false;
  var count = 0;

  await ldap.open();

  while (!done) {
    print('**** Query for $pageSize entries **** total count=$count');
    late SearchResult results;

    try {
      results = await ldap.query(baseDN, '(objectclass=*)', attrs,
          controls: [simplePaged, sss]);

      await for (var entry in results.stream) {
        // uncomment if you want to see the entries. Slow...
        print('$count: Got entry ${entry.dn} attrs = ${entry.attributes}');
        ++count;
      }

      //var sr = await results.getLdapResult();
      //print('LDAP result: $sr');
    } catch (e, s) {
      print('LDAP search exception $e\n$s');
    }

    var cookie = <int>[];
    if (results.controls.isNotEmpty) {
      for (var control in results.controls) {
        // print('Control $control');
        if (control is SimplePagedResultsControl) {
          if (control.isEmptyCookie) {
            done = true;
          } else {
            cookie = control.cookie;
          }
        }
      }

      // Update the control for the next page of results.
      // Note the DS server sets the returned page size to 0
      simplePaged = SimplePagedResultsControl(size: pageSize, cookie: cookie);
    }
  }

  try {
    await ldap.close();
  } catch (e) {
    print(e);
  }
}
