// test utility to load configuration from yaml

import "dart:io";
import 'package:dartdap/dartdap.dart';
import "package:yaml/yaml.dart";


Map<dynamic,dynamic> loadConfig(String file) {

  var f = new File(file);

  YamlMap m = loadYaml(f.readAsStringSync());
  return m["connections"];
}


LdapConnection getConnection(String file, String configName) {
  var p = loadConfig(file)[configName];

  assert( p != null );

  return LdapConnection(host: p["host"], ssl: p["ssl"], port: p["port"]);
}