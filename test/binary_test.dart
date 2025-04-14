import 'dart:convert';
import 'dart:io';
import 'package:asn1lib/asn1lib.dart';
import 'package:dartdap/dartdap.dart';
import 'package:test/test.dart';
import 'setup.dart';

void main() {
  late LdapConnection ldap;
  var testUserDN = DN('cn=testuser,ou=users,dc=example,dc=com');
  final file = File('test/etc/dart.jpeg'); // Ensure this file exists
  final jpegData = file.readAsBytesSync();
  final b64 = base64.encode(jpegData);

  setUpAll(() async {
    ldap = defaultConnection(ssl: true);
    await ldap.open();
    await ldap.bind();

    await deleteIfExists(ldap, testUserDN);
  });

  tearDownAll(() async {
    await deleteIfExists(ldap, testUserDN);
    await ldap.close();
  });

  test('Create user with jpegPhoto', () async {
    // Read a sample JPEG file

    // Create the user with the jpegPhoto attribute
    final attributes = {
      'objectClass': ['top', 'person', 'organizationalPerson', 'inetOrgPerson'],
      'cn': ['testuser'],
      'sn': ['Test'],
      // 'jpegPhoto;binary': ASN1OctetString.fromBytes(jpegData),
      // seems like openldap wants this as base64 string
      'jpegPhoto': b64,
      // Not really a cert - but just testing binary data
      // 'userCertificate': ASN1OctetString.fromBytes(jpegData),
      //'userPKCS12': ASN1OctetString.fromBytes(jpegData),
      // 'userPKCS12': b64,
    };

    var r = await ldap.add(testUserDN, attributes);
    print(r.diagnosticMessage);
    expect(r.resultCode, ResultCode.OK);
  });

  test('Query user with jpegPhoto', () async {
    var r = await ldap.query(testUserDN, '(objectClass=*)', ['cn', 'dn', 'jpegPhoto'], scope: SearchScope.BASE_LEVEL);

    await for (var sr in r.stream) {
      // print('Search result: ${sr.attributes}');
      var jpeg = sr.attributes['jpegPhoto'];

      expect(jpeg, isNotNull);
      expect(jpeg, isA<Attribute>());
      expect(jpeg?.values.length, 1);
      expect(jpeg?.values.first, isA<ASN1OctetString>());
      var s = jpeg?.values.first as ASN1OctetString;
      // bytes we get back should be the same as the bytes we created
      expect(s.utf8StringValue, b64);
    }
  });
}
