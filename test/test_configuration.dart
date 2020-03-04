import 'dart:io';
import 'package:dartdap/dartdap.dart';
import "package:safe_config/safe_config.dart";


class TestConfiguration extends Configuration {
  TestConfiguration(String filename): super.fromFile(File(filename));


  Map<String,LDAPConnectionConfiguration> connections;

  LdapConnection getConnection(String configName) {
    var c = connections[configName];
    return LdapConnection(
        host: c.host,
        ssl: c.ssl,
        port: c.port,
        bindDN: c.bindDN,
        password: c.password);
  }

}

class LDAPConnectionConfiguration extends Configuration {

  int port;
  @optionalConfiguration
  String host = "localhost";
  String baseDN;

  @optionalConfiguration
  String password = "password";

  @optionalConfiguration
  String bindDN = "cn=Directory Manager";

  @optionalConfiguration
  bool ssl = false;

}