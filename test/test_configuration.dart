import 'dart:io';
import "package:safe_config/safe_config.dart";


class TestConfiguration extends Configuration {
  TestConfiguration(String filename): super.fromFile(new File(filename));

  int port;
  String hostname;
  String baseDN;

  @optionalConfiguration
  String password = "password";

  @optionalConfiguration
  String bindDN = "cn=Directory Manager";


}