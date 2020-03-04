import 'package:dartdap/dartdap.dart';
import 'package:logging/logging.dart';

/// An example of performing a paged search using the SimplePagedResults Control
/// Tested against ForgeRock DS version 7.0
main() async {
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.time}: ${rec.loggerName}: ${rec.level.name}: ${rec.message}');
  });

  Logger.root.level = Level.INFO;

  var ldap = LdapConnection(
      host: 'localhost', port: 1389, bindDN: 'uid=admin', password: 'password');

  var baseDN = 'ou=people,ou=identities';
  var attrs = ['dn', 'uid'];
  var pageSize = 1000;

  // Create a control that pages through entries 'pageSize' at a time
  var simplePaged = SimplePagedResultsControl(size: pageSize);

  var done = false;
  int count = 0;

  while (!done)  {
    print("**** Query for $pageSize entries **** total count=$count");

    var results = await ldap.query(baseDN, '(objectclass=*)', attrs,
        controls: [simplePaged]);

    await for (var entry in results.stream) {
      // uncomment if you want to see the entries. Slow...
      //print("Got entry ${entry.dn} attrs = ${entry.attributes}");
      ++count;
    }

    print("LDAP result: ${results.ldapResult}");

    if (results.controls != null && results.controls.isNotEmpty) {
      // we should check for the control type .. this is hacky..
      // The server will send the paged result control back to us
      var s = results.controls[0] as SimplePagedResultsControl;
      // If the server sets the cookie to be empty, we are done
      if (s.isEmptyCookie  ) {
        done = true;
        break;
      }
      // Update the control for the next page of results.
      // Note the DS server sets the returned page size to 0
      simplePaged = SimplePagedResultsControl(size: pageSize, cookie: s.cookie);
    }
  }

  await ldap.close();
}
