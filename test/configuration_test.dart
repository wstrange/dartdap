// Tests for LDAPConfiguration
//
// These tests do not use a LDAP server. They only test the LDAP configuration, and not
// the connection to an LDAP server with those settings.
//
// Requirements: the "test/configuration_test.yaml" file

import 'dart:math';
import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';

const String CONFIG_FILE = "test/configuration_test.yaml";

void main() {
  var random = new Random();

  var host_value = "host-${random.nextInt(65535)}.example.com";
  var port_value = random.nextInt(65535);
  var ssl_value = random.nextBool();
  var bindDN_value = "dc=user-${random.nextInt(65535)},dc=example,dc=com";
  var password_value = "password${random.nextInt(65535)}";

  group("LDAP configuration default constructor", () {
    test("setting host only", () {
      var ldap_conf = new LDAPConfiguration(host_value);
      expect(ldap_conf, isNotNull);
      expect(ldap_conf.host, equals(host_value));
      expect(ldap_conf.port, equals(389));
      expect(ldap_conf.ssl, equals(false));
      expect(ldap_conf.bindDN, equals(""));
      expect(ldap_conf.password, equals(""));
    });

    test("setting host and port", () {
      var ldap_conf = new LDAPConfiguration(host_value, port: port_value);
      expect(ldap_conf, isNotNull);
      expect(ldap_conf.host, equals(host_value));
      expect(ldap_conf.port, equals(port_value));
      expect(ldap_conf.ssl, equals(false));
      expect(ldap_conf.bindDN, equals(""));
      expect(ldap_conf.password, equals(""));
    });

    test("setting host and ssl", () {
      var ldap_conf_ssl_false = new LDAPConfiguration(host_value, ssl: false);
      expect(ldap_conf_ssl_false, isNotNull);
      expect(ldap_conf_ssl_false.host, equals(host_value));
      expect(ldap_conf_ssl_false.port, equals(389));
      expect(ldap_conf_ssl_false.ssl, equals(false));
      expect(ldap_conf_ssl_false.bindDN, equals(""));
      expect(ldap_conf_ssl_false.password, equals(""));

      var ldap_conf_ssl_true = new LDAPConfiguration(host_value, ssl: true);
      expect(ldap_conf_ssl_true, isNotNull);
      expect(ldap_conf_ssl_true.host, equals(host_value));
      expect(ldap_conf_ssl_true.port, equals(636));
      expect(ldap_conf_ssl_true.ssl, equals(true));
      expect(ldap_conf_ssl_true.bindDN, equals(""));
      expect(ldap_conf_ssl_true.password, equals(""));
    });

    test("setting host, port and ssl", () {
      var ldap_conf_ssl_false =
          new LDAPConfiguration(host_value, port: port_value, ssl: false);
      expect(ldap_conf_ssl_false, isNotNull);
      expect(ldap_conf_ssl_false.host, equals(host_value));
      expect(ldap_conf_ssl_false.port, equals(port_value));
      expect(ldap_conf_ssl_false.ssl, equals(false));
      expect(ldap_conf_ssl_false.bindDN, equals(""));
      expect(ldap_conf_ssl_false.password, equals(""));

      var ldap_conf_ssl_true =
          new LDAPConfiguration(host_value, port: port_value, ssl: true);
      expect(ldap_conf_ssl_true, isNotNull);
      expect(ldap_conf_ssl_true.host, equals(host_value));
      expect(ldap_conf_ssl_true.port, equals(port_value));
      expect(ldap_conf_ssl_true.ssl, equals(true));
      expect(ldap_conf_ssl_true.bindDN, equals(""));
      expect(ldap_conf_ssl_true.password, equals(""));
    });

    test("setting all", () {
      var ldap_conf = new LDAPConfiguration(host_value,
          port: port_value,
          ssl: ssl_value,
          bindDN: bindDN_value,
          password: password_value);
      expect(ldap_conf, isNotNull);
      expect(ldap_conf.host, equals(host_value));
      expect(ldap_conf.port, equals(port_value));
      expect(ldap_conf.ssl, equals(ssl_value));
      expect(ldap_conf.bindDN, equals(bindDN_value));
      expect(ldap_conf.password, equals(password_value));
    });
  });

  group("LDAP configuration fromFile constructor", () {
    // create a connection. Return a future that completes when
    // the connection is available and bound
    setUp(() async {
      //  ldap = await ldapConfig.getConnection();
    });

    tearDown(() {
      // nothing to do. We can keep the connection open between tests
    });

    test("file not examined until needed", () {
      var ldap_conf = new LDAPConfiguration.fromFile("missing.yaml", "default");
      expect(ldap_conf, isNotNull);
    });

    test("missing file throws exception", () async {
      try {
        var ldap_conf =
            new LDAPConfiguration.fromFile("missing.yaml", "default");
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(
            e,
            new isInstanceOf<
                String>()); // TODO: code should be improved to give a meaningful exception
      }
    });

    test("missing config in file throws exception", () async {
      try {
        var ldap_conf = new LDAPConfiguration.fromFile(CONFIG_FILE, "missing");
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(e, new isInstanceOf<LdapException>());
      }
    });

    test("config is not a map throws exception", () async {
      try {
        var ldap_conf = new LDAPConfiguration.fromFile(CONFIG_FILE, "not_map");
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(e, new isInstanceOf<LdapException>());
      }
    });

    test("config missing host throws exception", () async {
      try {
        var ldap_conf = new LDAPConfiguration.fromFile(CONFIG_FILE, "is_map");
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(e, new isInstanceOf<LdapException>());
      }
    });

    // Add "host"

    test("host not string throws exception", () async {
      try {
        var ldap_conf =
            new LDAPConfiguration.fromFile(CONFIG_FILE, "host_not_string");
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(e, new isInstanceOf<LdapException>());
      }
    });

    test("host only loads", () async {
      var ldap_conf = new LDAPConfiguration.fromFile(CONFIG_FILE, "host_only");
      try {
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(ldap_conf.host, equals("no-domain.example.com")); // host loaded
        expect(ldap_conf.port, equals(389)); // port defaults to LDAP port
        expect(ldap_conf.ssl, equals(false)); // default to no TLS
        expect(ldap_conf.bindDN, equals("")); // default to no bindDN
        expect(ldap_conf.password, equals("")); // default to no password
        expect(e, new isInstanceOf<LdapSocketServerNotFoundException>()); // but could not connect
      }
    });

    // Add "port" value

    test("port not int throws exception", () async {
      var ldap_conf =
          new LDAPConfiguration.fromFile(CONFIG_FILE, "port_not_int");
      try {
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(e, new isInstanceOf<LdapException>());
      }
    });

    test("host and port value loads", () async {
      var ldap_conf = new LDAPConfiguration.fromFile(CONFIG_FILE, "port_value");
      try {
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(ldap_conf.host, equals("no-domain.example.com")); // host loaded
        expect(ldap_conf.port, equals(1024)); // port defaults to LDAP port
        expect(ldap_conf.ssl, equals(false)); // default to no TLS
        expect(ldap_conf.bindDN, equals("")); // default to no bindDN
        expect(ldap_conf.password, equals("")); // default to no password
        expect(e, new isInstanceOf<LdapSocketServerNotFoundException>()); // but could not connect
      }
    });

    // Add "ssl" value

    test("SSL not bool throws exception", () async {
      var ldap_conf =
          new LDAPConfiguration.fromFile(CONFIG_FILE, "ssl_not_bool");
      try {
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(e, new isInstanceOf<LdapException>());
      }
    });

    test("host and SSL false loaded correctly", () async {
      var ldap_conf =
          new LDAPConfiguration.fromFile(CONFIG_FILE, "no_port_ssl_false");
      try {
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(ldap_conf.host, equals("no-domain.example.com")); // host loaded
        expect(ldap_conf.port, equals(389)); // port defaults to LDAP port
        expect(ldap_conf.ssl, equals(false)); // ssl loaded
        expect(ldap_conf.bindDN, equals("")); // default to no bindDN
        expect(ldap_conf.password, equals("")); // default to no password
        expect(e, new isInstanceOf<LdapSocketServerNotFoundException>()); // but could not connect
      }
    });

    test("host and SSL true loaded correctly", () async {
      var ldap_conf =
          new LDAPConfiguration.fromFile(CONFIG_FILE, "no_port_ssl_true");
      try {
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(ldap_conf.host, equals("no-domain.example.com")); // host loaded
        expect(ldap_conf.port, equals(636)); // port defaults to LDAPS port
        expect(ldap_conf.ssl, equals(true)); // ssl loaded
        expect(ldap_conf.bindDN, equals("")); // default to no bindDN
        expect(ldap_conf.password, equals("")); // default to no password
        expect(e, new isInstanceOf<LdapSocketServerNotFoundException>()); // but could not connect
      }
    });

    test("host and SSL true loaded correctly", () async {
      var ldap_conf =
          new LDAPConfiguration.fromFile(CONFIG_FILE, "post_and_ssl_false");
      try {
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(ldap_conf.host, equals("no-domain.example.com")); // host loaded
        expect(ldap_conf.port, equals(512)); // port defaults to LDAPS port
        expect(ldap_conf.ssl, equals(false)); // ssl loaded
        expect(ldap_conf.bindDN, equals("")); // default to no bindDN
        expect(ldap_conf.password, equals("")); // default to no password
        expect(e, new isInstanceOf<LdapSocketServerNotFoundException>()); // but could not connect
      }
    });

    test("host and SSL true loaded correctly", () async {
      var ldap_conf =
          new LDAPConfiguration.fromFile(CONFIG_FILE, "post_and_ssl_true");
      try {
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(ldap_conf.host, equals("no-domain.example.com")); // host loaded
        expect(ldap_conf.port, equals(512)); // port defaults to LDAPS port
        expect(ldap_conf.ssl, equals(true)); // ssl value was loaded
        expect(ldap_conf.bindDN, equals("")); // default to no bindDN
        expect(ldap_conf.password, equals("")); // default to no password
        expect(e, new isInstanceOf<LdapSocketServerNotFoundException>()); // but could not connect
      }
    });

    // Add bindDN and password

    test("bindDN and password loaded correctly", () async {
      var ldap_conf =
          new LDAPConfiguration.fromFile(CONFIG_FILE, "bindDN_and_password");
      try {
        await ldap_conf.getConnection();
        expect(false, isTrue, reason: "Unreachable");
      } catch (e) {
        expect(ldap_conf.host, equals("no-domain.example.com")); // host loaded
        expect(ldap_conf.port, equals(389)); // port defaults to LDAPS port
        expect(ldap_conf.ssl, equals(false)); // ssl value was loaded
        expect(ldap_conf.bindDN, equals("dc=example,dc=com")); // bindDN loaded
        expect(ldap_conf.password, equals("p@ssw0rd")); // password loaded
        expect(e, new isInstanceOf<LdapSocketServerNotFoundException>()); // but could not connect
      }
    });
  });
}
