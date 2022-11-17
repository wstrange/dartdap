part of ldap_protocol;
// Abandon an LDAP operation. The server may not honour this request.
// A response is not expected.

// AbandonRequest ::= [APPLICATION 16] MessageID
class AbandonRequest extends RequestOp {
  final int _messageId; // the message ID to cancel

  // Abandon the request specified by messageId
  // Note that an Abandon of message Id 0 can be used
  // to keep an ldap connection alive.
  // See https://stackoverflow.com/questions/313575/ldap-socket-keep-alive
  AbandonRequest(this._messageId) : super(ABANDON_REQUEST);

  int get messageId => _messageId;

  @override
  ASN1Object toASN1() {
    return ASN1Integer.fromInt(_messageId, tag: ABANDON_REQUEST);
  }
}
