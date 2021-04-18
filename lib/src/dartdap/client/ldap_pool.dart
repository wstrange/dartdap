import 'package:dartdap/src/dartdap/control/control.dart';
import 'package:dartdap/src/dartdap/core/filter.dart';
import 'package:dartdap/src/dartdap/core/ldap_result.dart';
import 'package:dartdap/src/dartdap/core/modification.dart';
import 'package:dartdap/src/dartdap/core/search_result.dart';
import 'package:dartdap/src/dartdap/protocol/ldap_protocol.dart';
import '../../../dartdap.dart';
import 'ldap_connection.dart';
import 'dart:async';
import 'ldap.dart';

// Some prior art:
// See https://github.com/brettwooldridge/HikariCP
// todo: this is where we set retry, etc.
/// Unbound approach:
///   LDAPConnection connection = new LDAPConnection(address, port);
//    BindResult bindResult = connection.bind(bindDN, password);
//    LDAPConnectionPool connectionPool = new LDAPConnectionPool(connection, 10);
// Create a new LDAP connection pool with 10 connections spanning multiple
// servers using a server set.
// RoundRobinServerSet serverSet = new RoundRobinServerSet(addresses, ports);
// SimpleBindRequest bindRequest = new SimpleBindRequest(bindDN, password);
// LDAPConnectionPool connectionPool =
// new LDAPConnectionPool(serverSet, bindRequest, 10);

// https://docs.ldap.com/ldap-sdk/docs/javadoc/com/unboundid/ldap/sdk/FailoverServerSet.html
// DS SDK
// https://backstage.forgerock.com/docs/ds/7/javadoc/org/forgerock/opendj/ldap/ConnectionPool.html
// implemented LdapClient and close()
// Uses same model - pass a client
// SharedConnectionPool​(LdapClient client, int poolSize)
// https://backstage.forgerock.com/docs/ds/7/javadoc/org/forgerock/opendj/ldap/SharedConnectionPool.html

// typedef Future<LdapResult> LdapFunction();

///
/// TODO
/// https://api.dart.dev/stable/2.10.4/dart-async/runZonedGuarded.html
///
///
///
class LdapPoolException implements Exception {
  final String msg;
  final LdapResult? result;

  LdapPoolException(this.msg, [this.result]);
}

/// LdapConnectionPool implements a very simple connection pool handler.
///
/// To create a pool, pass in an [LdapConnection]:
/// ```
///    var pool = LdapConnectionPool(ldapConnection);
/// ```
/// The pool will create up to [_poolSize] instances by cloning the connection. The
/// socket connection
/// will be retried up to [_maxOpenRetries] times.
///
/// The pool implements the [LdapConnection] interface. You can directly
/// use the pool instance:
/// ```
/// pool.search(...); pool.add(...)
/// ```
///
/// Or alternatively, you can get a LdapConnection and return it to the
/// pool when done:
///
/// ```
/// var c = pool.getConnection();
/// c.search(....); c.add(..)
/// pool.releaseConnection(c);
/// ```
/// The later approach is preferred if you want to alter the bind credentials
/// or resuse the same connection.
///
/// Features not yet implemented:
/// * Health Checks
/// * TCP Keep alive on the connection
/// * Retry operation (other than open(), operations are not retried)
/// * ldap referral handling
/// * Multiple host support, HA fail over etc.
///
class LdapConnectionPool extends Ldap {
  late final LdapConnection _protoConnection;
  List<LdapConnection> pool = [];
  final int _poolSize;
  final int _maxOpenRetries;
  late List<LdapConnection> _connections;

  ///
  /// Create a connection pool based on the ldap [connection]. The pool
  /// will be up to [poolSize] copies of the connection. Connections in
  /// the pool will be retried up to [maxOpenRetries].
  LdapConnectionPool(LdapConnection connection,
      {poolSize = 5, maxOpenRetries = 10})
      : _protoConnection = connection,
        _poolSize = poolSize,
        _maxOpenRetries = maxOpenRetries {
    assert(_poolSize >= 1 && _poolSize < 20);
    var l = <LdapConnection>[];
    for (var i = 0; i < _poolSize; ++i) {
      var c = LdapConnection.copy(_protoConnection);
      c.connectionInfo.id = i;
      l.add(c);
    }
    _connections = List.unmodifiable(l);
  }

  /// Return a [LdapConnection] from the pool. If [bind] is true (default)
  /// An ldap bind will be performed using the credentials provided in the
  /// original [LdapConnection] used to create the pool.
  Future<LdapConnection> getConnection({bool bind = true}) async {
    // https://github.com/dart-lang/sdk/issues/42947  firstWhere does not work here
    // var c = _connections.firstWhere((c) => c.connectionInfo.inUse == false , orElse: () => null);
    loggerPool.finest('pool getConnection bind=$bind');
    LdapConnection? c;
    for (final cx in _connections) {
      if (cx.connectionInfo.inUse == false) {
        c = cx;
        break;
      }
    }
    if (c == null) {
      throw LdapPoolException('All pool connections are in use');
    }

    if (c.state == ConnectionState.closed ||
        c.state == ConnectionState.disconnected) {
      await _open(c);
    }

    // If bind is true and the connection is not already bound...
    if (bind && c.state != ConnectionState.bound) {
      var result = await c.bind();
      if (result.resultCode != ResultCode.OK) {
        throw LdapPoolException('LdapPool can not bind connection', result);
      }
    }
    c.connectionInfo.inUse = true;
    return c;
  }

  void releaseConnection(LdapConnection c) {
    c.connectionInfo.inUse = false;
  }

  // @override
  // bool get isBound => _protoConnection.isBound;

  @override
  Future<LdapResult> add(String dn, Map<String, dynamic> attrs) {
    return _ldapFunction((LdapConnection c) {
      return c.add(dn, attrs);
    });
  }

  @override
  Future<LdapResult> bind({String? DN, String? password}) async {
    var c = await getConnection(bind: false);
    LdapResult result;
    if (DN != null && password != null) {
      loggerPool.finest(() => 'bind($DN)');
      result = await c.bind(DN: DN, password: password);
    } else {
      result = await c.bind();
    }
    loggerPool.finest(() => 'Bind result $result');
    return result;
  }

  // closing a pool connection closes all connections
  Future<void> close() async {
    loggerPool.info('Closing all pool connections');
    for(var c in _connections) {
      if (c.state == ConnectionState.bound ||
          c.state == ConnectionState.ready) {
        loggerPool.fine('Pool closing connection ${c.connectionInfo.id}');
        await c.close();
      }
    }
  }

  // close the pool
  Future<void> destroy() async {
    await Future.forEach(_connections, (LdapConnection c) async {
      await c.close();
    });
  }

  @override
  Future<LdapResult> compare(
      String dn, String attrName, String attrValue) async {
    return _ldapFunction((LdapConnection c) {
      return c.compare(dn, attrName, attrValue);
    });
  }

  @override
  Future<LdapResult> delete(String dn) {
    return _ldapFunction((LdapConnection c) {
      return c.delete(dn);
    });
  }

  @override
  Future<LdapResult> modify(String dn, List<Modification> mods) {
    return _ldapFunction((LdapConnection c) {
      return c.modify(dn, mods);
    });
  }

  @override
  Future<LdapResult> modifyDN(String dn, String rdn,
      {bool deleteOldRDN = true, String? newSuperior}) {
    return _ldapFunction((LdapConnection c) {
      return c.modifyDN(dn, rdn,
          deleteOldRDN: deleteOldRDN, newSuperior: newSuperior);
    });
  }

  @override
  Future<SearchResult> search(
      String baseDN, Filter filter, List<String> attributes,
      {int scope = SearchScope.SUB_LEVEL,
      int sizeLimit = 0,
      List<Control> controls = const <Control>[]}) async {
    LdapConnection? c;
    try {
      c = await getConnection();
      var sr = await c.search(baseDN, filter, attributes,
          scope: scope, sizeLimit: sizeLimit, controls: controls);
      return sr;
    } catch (e) {
      loggerPool.severe('search error', e);
      rethrow;
    } finally {
      if (c != null) {
        releaseConnection(c);
      }
    }
  }

  Future<void> open() async {
    loggerPool.warning(
        'open() called on pool connection. This is not required. Use getConnection() instead');
  }

  // Open a socket ldap connection to the server. This does NOT perform a bind.
  Future<void> _open(LdapConnection c) async {
    // retry
    var count = 0;

    while (count < _maxOpenRetries) {
      try {
        await c.open();
        // open was OK
        return;
      } catch (e) {
        if (e is LdapSocketException ||
            e is LdapSocketRefusedException ||
            e is LdapSocketServerNotFoundException) {
          loggerPool.info(
              'Cant open socket to ${c.url}. Will retry again later', e);
        } else {
          // we can't fix these exception types;
          loggerPool.severe('Cant open ldap connection to ${c.url}', e);
          rethrow;
        }
      }
      ++count;
      await Future.delayed(const Duration(seconds: 10));
    }

    // todo: Better exception to throw?
    throw LdapConfigException(
        'Cant connect to server ${c.url} after $_maxOpenRetries tries');
  }

  // Call the supplied ldap function that returns an ldap result
  Future<LdapResult> _ldapFunction(
      Future<LdapResult> Function(LdapConnection) f) async {
    LdapConnection? c;
    try {
      c = await getConnection(bind: true);
      var r = await f(c);
      return r;
    } catch (e) {
      loggerPool.warning('LdapPool exception', e);
      rethrow;
    } finally {
      if (c != null) {
        releaseConnection(c);
      }
    }
  }

  // Calls a user supplied function to check the health of a specific connection
  // Note that a bind() is not automatically done on the connection.
  // TODO: This is not implemented yet
  // Future<LdapResult> _ldapHealthCheck(
  //     LdapConnection c, Future<LdapResult> Function(LdapConnection) f) async {
  //   try {
  //     // call the user supplied function
  //     var result = await f(c);
  //     return result;
  //   } catch (e) {
  //     loggerPool.warning('Health check failed', e);
  //     rethrow;
  //   }
  // }
}
