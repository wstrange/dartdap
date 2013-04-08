library ldap_protocol;

import 'dart:typeddata';
import 'dart:isolate';
import 'package:asn1lib/asn1lib.dart';
import 'package:logging/logging.dart';

import '../filter.dart';
import '../ldap_exception.dart';
import '../ldap_util.dart';
import '../ldap_result.dart';
import '../attribute.dart';
import '../search_scope.dart';
import '../modification.dart';

part 'protocol_op.dart';
part 'bind_request.dart';
part 'search_request.dart';
part 'ldap_responses.dart';
part 'ldap_message.dart';
part 'response_handler.dart';
part 'search_result_entry.dart';
part 'add_request.dart';
part 'delete_request.dart';
part 'modify_request.dart';


// top level constants
// todo: Should we put these in a class?
const int BIND_REQUEST    = 0x60;
const int BIND_RESPONSE   = 0x61;
const int UNBIND_REQUEST  = 0x62;


const int SEARCH_REQUEST = 0x63;
const int SEARCH_RESULT_ENTRY = 0x64;
const int SEARCH_RESULT_DONE = 0x65;
const int SEARCH_RESULT_REFERENCE = 0x73;
const int MODIFY_REQUEST = 0x66;
const int MODIFY_RESPONSE = 0x67;


const int ADD_REQUEST = 0x68;
const int ADD_RESPONSE = 0x69;

const int EXTENDED_RESPONSE = 0x78;

const int DELETE_REQUEST = 0x4A;
const int DELETE_RESPONSE = 0x6B;
const int MODIFY_DN_REQUEST = 0x6C;
const int MODIFY_DN_RESPONSE = 0x6D;
const int COMPARE_REQUEST = 0x6E;
const int COMPARE_RESPONSE = 0x6F;
const int ABANDON_REQUEST = 0x50;
const int EXTENDED_REQUEST = 0x77;
const int INTERMEDIATE_RESPONSE = 0x79;



const int CONTROLS = 0xA0;




String _op2String(int op) {
  switch(op) {
    case BIND_REQUEST: return "BND_REQ";
    case BIND_RESPONSE: return "BND_RESP";
    case SEARCH_REQUEST: return "SRCH_REQ";
    case SEARCH_RESULT_ENTRY: return "SRCH_RES_ENTRY";
    case SEARCH_RESULT_DONE: return "SRCH_RES_DONE";
    case SEARCH_RESULT_REFERENCE: return "SRCH_RES_REF";
    case MODIFY_REQUEST:  return "MODIFY_REQUEST";
    case ADD_REQUEST: return "ADD_REQUEST";
    case ADD_RESPONSE: return "ADD_RESPONSE";
    // todo add more...
    default: return op.toRadixString(16);

  }
}

Logger logger = new Logger("ldap_protocol");

