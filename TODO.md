# TODO

Notes on things to improve, etc.

## Misc

* Paged search
* VLV Search. See [https://tools.ietf.org/html/draft-ietf-ldapext-ldapv3-vlv-09]
* An LDIF parser would be nice for creating integration test data
* Do we need to implement flow control so the client does not overwhelm
  the server?
* Type safety. Things like a DN should be Dart objects, not strings

## Connection Pooling

The connection pool is very much a work in progress. Feedback is appreciated.

The LdapConnectionPool class wraps an LdapConnection object, and provides the following features:

* A keepalive request is sent on on all open connections (keepAliveSeconds - default 30) to attempt
 to keep the server from dropping the connection. The default keep alive
  function sends an Ldap Abandon request for message id 0. You can provide your own keep alive function.
* If the server is not up, the pool will retry the connection (parameter maxOpenRetries, defaults to 10 attempts),
 with a 10 second delay between attempts.
* To perform operation, get an Ldap Connection (pool.getConnection), perform operations,
  and then when done pool.releaseConnection
* Alternatively, The pool implements the [Ldap] interface. You can directly perform add/bind/search, etc. on
the pool.

```dart
pool.add(...);

// Is equivalent to:
var c = pool.getConnection();
c.add(); /// etc...
pool.releaseConnection(c);
```

See the sample in [pool.dart](example/pool.dart)

Note that if you re-bind a connection, that connection
remains bound as the last user - not the original user you created with the prototype LdapConnection.

If you want to frequently bind as a different user (for example to test authentication), create
a separate pool for that purpose.
