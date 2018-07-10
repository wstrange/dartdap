// test utility to load configuration from yaml

import "dart:io";
import "package:yaml/yaml.dart";


Map<dynamic,dynamic> loadConfiguration(String file) {

  var f = new File(file);

  YamlMap m = loadYaml(f.readAsStringSync());
  return m;
}