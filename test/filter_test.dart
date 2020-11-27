/// Unit tests for filter encodings

import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';

// TODO: We should also test the query parser as well.
// One test for the Filter(), one to see if the Filter() created by the parser
// also produces the same encoding.
//
void main() {
  group('Filter Encoding', () {
    test('(foo=bar)', () {
      var f = Filter.equals('foo', 'bar');
      var b = f.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0xa3,
            0x0a,
            0x04,
            0x03,
            0x66,
            0x6f,
            0x6f,
            0x04,
            0x03,
            0x62,
            0x61,
            0x72
          ]));
    });

    test('(foo<=bar)', () {
      var f = Filter.lessOrEquals('foo', 'bar');
      var b = f.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0xa6,
            0x0a,
            0x04,
            0x03,
            0x66,
            0x6f,
            0x6f,
            0x04,
            0x03,
            0x62,
            0x61,
            0x72
          ]));
    });

    test('(foo>=bar)', () {
      var f = Filter.greaterOrEquals('foo', 'bar');
      var b = f.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0xa5,
            0x0a,
            0x04,
            0x03,
            0x66,
            0x6f,
            0x6f,
            0x04,
            0x03,
            0x62,
            0x61,
            0x72
          ]));
    });

    test('(foo~=bar)', () {
      var f = Filter.approx('foo', 'bar');
      var b = f.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0xa8,
            0x0a,
            0x04,
            0x03,
            0x66,
            0x6f,
            0x6f,
            0x04,
            0x03,
            0x62,
            0x61,
            0x72
          ]));
    });

    test('(foo=bar*)', () {
      var f = Filter.substring('foo', 'bar*');
      var b = f.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0xa4,
            0x0c,
            0x04,
            0x03,
            0x66,
            0x6f,
            0x6f,
            0x30,
            0x05,
            0x80,
            0x03,
            0x62,
            0x61,
            0x72
          ]));
    });

    test('(foo=*)', () {
      var f = Filter.present('foo');
      var b = f.toASN1().encodedBytes;
      expect(b, equals([0x87, 0x03, 0x66, 0x6f, 0x6f]));
    });

    test('(!(foo=bar))', () {
      var f = Filter.not(Filter.equals('foo', 'bar'));
      var b = f.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0xa2,
            0x0c,
            0xa3,
            0x0a,
            0x04,
            0x03,
            0x66,
            0x6f,
            0x6f,
            0x04,
            0x03,
            0x62,
            0x61,
            0x72
          ]));
    });

    test('(!(foo<=bar))', () {
      var f = Filter.not(Filter.lessOrEquals('foo', 'bar'));
      var b = f.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0xa2,
            0x0c,
            0xa6,
            0x0a,
            0x04,
            0x03,
            0x66,
            0x6f,
            0x6f,
            0x04,
            0x03,
            0x62,
            0x61,
            0x72
          ]));
    });

    test('(!(foo>=bar))', () {
      var f = Filter.not(Filter.greaterOrEquals('foo', 'bar'));
      var b = f.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0xa2,
            0x0c,
            0xa5,
            0x0a,
            0x04,
            0x03,
            0x66,
            0x6f,
            0x6f,
            0x04,
            0x03,
            0x62,
            0x61,
            0x72
          ]));
    });

    test('(!(foo~=bar))', () {
      var f = Filter.not(Filter.approx('foo', 'bar'));
      var b = f.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0xa2,
            0x0c,
            0xa8,
            0x0a,
            0x04,
            0x03,
            0x66,
            0x6f,
            0x6f,
            0x04,
            0x03,
            0x62,
            0x61,
            0x72
          ]));
    });

    test('(!(foo=*))', () {
      var f = Filter.not(Filter.present('foo'));
      var b = f.toASN1().encodedBytes;
      expect(b, equals([0xa2, 0x05, 0x87, 0x03, 0x66, 0x6f, 0x6f]));
    });

    test('(&(foo=bar)(baz=banana))', () {
      var f = Filter.and(
          [Filter.equals('foo', 'bar'), Filter.equals('baz', 'banana')]);
      var b = f.toASN1().encodedBytes;
      expect(
          b,
          equals([
            0xa0,
            0x1b,
            0xa3,
            0x0a,
            0x04,
            0x03,
            0x66,
            0x6f,
            0x6f,
            0x04,
            0x03,
            0x62,
            0x61,
            0x72,
            0xa3,
            0x0d,
            0x04,
            0x03,
            0x62,
            0x61,
            0x7a,
            0x04,
            0x06,
            0x62,
            0x61,
            0x6e,
            0x61,
            0x6e,
            0x61
          ]));
    });
  });
}
