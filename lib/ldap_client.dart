
library ldapclient;

import 'package:logging/logging.dart';


export 'src/ldap_connection.dart';
export 'src/ldap_exception.dart';
export 'src/filter.dart';
export 'src/attribute.dart';
export 'src/ldap_result.dart';
export 'src/search_scope.dart';

Logger logger = new Logger("ldapclient");


// what is the proper way to do this???
initLogging() {
  Logger.root.level = Level.FINEST;
  logger.on.record.add( (LogRecord r) {
    print("${r.loggerName}:${r.sequenceNumber}:${r.time}:${r.message}");
    });
}