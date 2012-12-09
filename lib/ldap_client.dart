
library ldapclient;

import 'dart:scalarlist';
import 'dart:io';
import 'dart:isolate';
import 'package:asn1lib/asn1lib.dart';
import 'package:logging/logging.dart';


import 'package:dartdap/src/protocol/ldap_protocol.dart';
export 'package:dartdap/src/protocol/ldap_protocol.dart' show LDAPResult, LDAPException, Filter, SubstringFilter, SearchResult;



part 'ldap_connection.dart';


Logger logger = new Logger("ldapclient");


// what is the proper way to do this???
initLogging() {
  Logger.root.level = Level.FINEST;
  logger.on.record.add( (LogRecord r) {
    print("${r.loggerName}:${r.sequenceNumber}:${r.time}:${r.message}");
    });
}