/// Unit tests for control encodings
//@Skip('currently failing')

import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';

void main() {
  group('Sort Control', () {
    test('cn ascending', () {
      var c = ServerSideSortRequestControl([SortKey('cn')]);
      var b = c.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0x30,
            0x22,
            0x04,
            0x16,
            0x31,
            0x2e,
            0x32,
            0x2e,
            0x38,
            0x34,
            0x30,
            0x2e,
            0x31,
            0x31,
            0x33,
            0x35,
            0x35,
            0x36,
            0x2e,
            0x31,
            0x2e,
            0x34,
            0x2e,
            0x34,
            0x37,
            0x33,
            0x04,
            0x08,
            0x30,
            0x06,
            0x30,
            0x04,
            0x04,
            0x02,
            0x63,
            0x6e
          ]));
    });

    test('cn descending', () {
      var c = ServerSideSortRequestControl([SortKey('cn', null, true)]);
      var b = c.toASN1().encodedBytes;
      // fails, waiting for asn1boolean tagging fix
      expect(
          b,
          equals([
            0x30,
            0x25,
            0x04,
            0x16,
            0x31,
            0x2e,
            0x32,
            0x2e,
            0x38,
            0x34,
            0x30,
            0x2e,
            0x31,
            0x31,
            0x33,
            0x35,
            0x35,
            0x36,
            0x2e,
            0x31,
            0x2e,
            0x34,
            0x2e,
            0x34,
            0x37,
            0x33,
            0x04,
            0x0b,
            0x30,
            0x09,
            0x30,
            0x07,
            0x04,
            0x02,
            0x63,
            0x6e,
            0x81,
            0x01,
            0xff
          ]));
    });

    test('cn sn ascending', () {
      var cn = SortKey('cn');
      var sn = SortKey('sn');
      var c = ServerSideSortRequestControl([cn, sn]);
      var b = c.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0x30,
            0x28,
            0x04,
            0x16,
            0x31,
            0x2e,
            0x32,
            0x2e,
            0x38,
            0x34,
            0x30,
            0x2e,
            0x31,
            0x31,
            0x33,
            0x35,
            0x35,
            0x36,
            0x2e,
            0x31,
            0x2e,
            0x34,
            0x2e,
            0x34,
            0x37,
            0x33,
            0x04,
            0x0e,
            0x30,
            0x0c,
            0x30,
            0x04,
            0x04,
            0x02,
            0x63,
            0x6e,
            0x30,
            0x04,
            0x04,
            0x02,
            0x73,
            0x6e
          ]));
    });
  });

  group('VLV Control', () {
    test('assertion', () {
      var c =
          VLVRequestControl.assertionControl('example', 0, 19, critical: true);
      var b = c.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0x30,
            0x2f,
            0x04,
            0x17,
            0x32,
            0x2e,
            0x31,
            0x36,
            0x2e,
            0x38,
            0x34,
            0x30,
            0x2e,
            0x31,
            0x2e,
            0x31,
            0x31,
            0x33,
            0x37,
            0x33,
            0x30,
            0x2e,
            0x33,
            0x2e,
            0x34,
            0x2e,
            0x39,
            0x01,
            0x01,
            0xff,
            0x04,
            0x11,
            0x30,
            0x0f,
            0x02,
            0x01,
            0x00,
            0x02,
            0x01,
            0x13,
            0x81,
            0x07,
            0x65,
            0x78,
            0x61,
            0x6d,
            0x70,
            0x6c,
            0x65
          ]));
    });

    test('offset', () {
      var c =
          VLVRequestControl.offsetControl(1, 0, 0, 19, null, critical: true);
      var b = c.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0x30,
            0x2e,
            0x04,
            0x17,
            0x32,
            0x2e,
            0x31,
            0x36,
            0x2e,
            0x38,
            0x34,
            0x30,
            0x2e,
            0x31,
            0x2e,
            0x31,
            0x31,
            0x33,
            0x37,
            0x33,
            0x30,
            0x2e,
            0x33,
            0x2e,
            0x34,
            0x2e,
            0x39,
            0x01,
            0x01,
            0xff,
            0x04,
            0x10,
            0x30,
            0x0e,
            0x02,
            0x01,
            0x00,
            0x02,
            0x01,
            0x13,
            0xa0,
            0x06,
            0x02,
            0x01,
            0x01,
            0x02,
            0x01,
            0x00
          ]));
    });
  });
}
