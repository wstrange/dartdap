
import 'package:dartdap/src/dartdap/protocol/ldap_protocol.dart';
import '../../../dartdap.dart';
import 'dart:async';
import 'package:collection/collection.dart';

class LdapPoolException implements Exception {
  final String msg;
  final LdapResult? result;

  LdapPoolException(this.msg, [this.result]);
}

typedef LdapFunction = Future<bool> Function(LdapConnection c);

/// LdapConnectionPool implements a very simple connection pool handler.
///
/// To create a pool, pass in an [LdapConnection]:
/// ```
///    var pool = LdapConnectionPool(ldapConnection);
/// ```
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
/// or reuse the same connection.
///
/// Features not yet implemented:
/// * Health Checks
/// * ldap referral handling
/// * Multiple host support, HA fail over etc.
///
class LdapConnectionPool extends Ldap {
  late final LdapConnection _protoConnection;
  List<LdapConnection> pool = [];
  final int _poolSize;
  final int _maxOpenRetries;
  late List<LdapConnection> _connections;
  final Future<bool> Function(LdapConnection c) _keepAliveFunction;
  final int _keepAliveTimerSeconds;

  ///
  /// Create a connection pool based on a prototype [LdapConnection]. The pool
  /// will be up to [poolSize] copies of the connection. An
  /// attempt to open the connection up to [maxOpenRetries] will be made
  /// with an interval of 10 seconds between each attempt.
  /// Every [keepAliveTimerSeconds] the pool will send a keep alive
  /// request to the server. The default keep alive function
  /// sends an Ldap Abandon request with message id = 0. Most servers
  /// will ignore this request.
  ///
  LdapConnectionPool(
    LdapConnection connection, {
    poolSize = 5,
    maxOpenRetries = 10,
    keepAliveTimerSeconds = 30,
    LdapFunction keepAliveFunction = _defaultKeepAliveFunction,
  })  : _protoConnection = connection,
        _poolSize = poolSize,
        _maxOpenRetries = maxOpenRetries,
        _keepAliveFunction = keepAliveFunction,
        _keepAliveTimerSeconds = keepAliveTimerSeconds {
    assert(_poolSize >= 1 && _poolSize < 20);
    var l = <LdapConnection>[];
    for (var i = 0; i < _poolSize; ++i) {
      var c = LdapConnection.copy(_protoConnection);
      c.connectionInfo.id = c.connectionId;
      l.add(c);
    }
    _connections = List.unmodifiable(l);

    // create a keep alive timer
    Timer.periodic(Duration(seconds: _keepAliveTimerSeconds), (timer) {
      for (var connection in _connections) {
        _keepAliveFunction(connection);
      }
    });
  }

  /// Return a [LdapConnection] from the pool. If [bind] is true
  /// An ldap bind will be performed using the credentials provided in the
  /// original [LdapConnection] used to create the pool.
  Future<LdapConnection> getConnection({bool bind = false}) async {
    loggerPool.finest('pool getConnection bind=$bind');
    var c =
        _connections.firstWhereOrNull((c) => c.connectionInfo.inUse == false);
    if (c == null) {
      throw LdapPoolException(
          'No available connections in the pool. Does your code leak connections?');
    }

    if (c.state == ConnectionState.closed) {
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

  /// Release a connection back to the pool
  /// If repairBadConnection is true, try to repair the connection by closing/opening
  ///
  Future<void> releaseConnection(LdapConnection c,
      {bool repairBadConnection = false}) async {
    c.connectionInfo.inUse = false;
    if (repairBadConnection) {
      try {
        await c.close();
        await _open(c);
      } catch (e) {
        loggerPool.severe('Could not repair $c');
      }
    }
  }

  @override
  Future<LdapResult> add(DN dn, Map<String, dynamic> attrs) {
    return _ldapFunction((LdapConnection c) {
      return c.add(dn, attrs);
    });
  }

  @override
  Future<LdapResult> bind({DN? DN, String? password}) async {
    var c = await getConnection(bind: false);
    try {
      LdapResult result;
      if (DN != null && password != null) {
        loggerPool.finest(() => 'bind($DN)');
        result = await c.bind(DN: DN, password: password);
      } else {
        result = await c.bind();
      }
      loggerPool.finest(() => 'Bind result $result');
      return result;
    } on LdapException catch (e) {
      loggerPool.severe(e);
    } finally {
      await releaseConnection(c);
    }
    throw LdapPoolException('Could not bind');
  }

  // closing a pool connection closes all connections
  Future<void> close() async {
    loggerPool.info('Closing all pool connections');
    for (var c in _connections) {
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
  Future<LdapResult> compare(DN dn, String attrName, String attrValue) async {
    return _ldapFunction((LdapConnection c) {
      return c.compare(dn, attrName, attrValue);
    });
  }

  @override
  Future<LdapResult> delete(DN dn) {
    return _ldapFunction((LdapConnection c) {
      return c.delete(dn);
    });
  }

  @override
  Future<LdapResult> modify(DN dn, List<Modification> mods) {
    return _ldapFunction((LdapConnection c) {
      return c.modify(dn, mods);
    });
  }

  @override
  Future<LdapResult> modifyDN(DN dn, String rdn,
      {bool deleteOldRDN = true, String? newSuperior}) {
    return _ldapFunction((LdapConnection c) {
      return c.modifyDN(dn, rdn,
          deleteOldRDN: deleteOldRDN, newSuperior: newSuperior);
    });
  }

  @override
  Future<SearchResult> search(
      DN baseDN, Filter filter, List<String> attributes,
      {int scope = SearchScope.SUB_LEVEL,
      int sizeLimit = 0,
      List<Control> controls = const <Control>[]}) async {
    LdapConnection? c;
    try {
      c = await getConnection();
      var sr = await c.search(baseDN, filter, attributes,
          scope: scope, sizeLimit: sizeLimit, controls: controls);
      return sr;
    } catch (e, stacktrace) {
      loggerPool.severe('search error $e. Stack $stacktrace', stacktrace);
      rethrow;
    } finally {
      if (c != null) {
        await releaseConnection(c);
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
  // Used to wrap pool calls for all everything other than searches
  Future<LdapResult> _ldapFunction(
      Future<LdapResult> Function(LdapConnection) f) async {
    LdapConnection? c;
    try {
      c = await getConnection();
      var r = await f(c);
      return r;
    } on LdapException catch (e) {
      loggerPool.severe('LdapPool exception', e);
      rethrow;
    } catch (e) {
      loggerPool.severe('LdapPool other exception', e);
      rethrow;
    } finally {
      if (c != null) {
        await releaseConnection(c);
      }
    }
  }

  // default function to keep a connection alive.
  /// Sends an abandon of message id 0 which the server will ignore
  ///
  static Future<bool> _defaultKeepAliveFunction(LdapConnection c) async {
    // abandon request of id = 0 will be a no-op for the server
    if (c.isReady) {
      c.abandonRequest(messageId: 0);
      loggerPool.fine('Keep alive $c');
    }
    return true;
  }
}
