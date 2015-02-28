/// Unit test for filter encodings


/*
 * Obj C test supplied by Chris.  TODO: Convert this to a Dart unit test
 *
 * [eq writeFilter:@"(foo=bar)"];
    uint8_t eq_bytes[] = { 0xa3, 0x0a, 0x04, 0x03, 'f', 'o', 'o', 0x04, 0x03, 'b', 'a', 'r' };

    [le writeFilter:@"(foo<=bar)"];
    uint8_t lt_bytes[] = { 0xa6, 0x0a, 0x04, 0x03, 'f', 'o', 'o', 0x04, 0x03, 'b', 'a', 'r' };

    [ge writeFilter:@"(foo>=bar)"];
    uint8_t gt_bytes[] = { 0xa5, 0x0a, 0x04, 0x03, 'f', 'o', 'o', 0x04, 0x03, 'b', 'a', 'r' };

    [ap writeFilter:@"(foo~=bar)"];
    uint8_t ap_bytes[] = { 0xa8, 0x0a, 0x04, 0x03, 'f', 'o', 'o', 0x04, 0x03, 'b', 'a', 'r' };

    [ls writeFilter:@"(foo=bar*)"];
    uint8_t ls_bytes[] = { 0xa4, 0x0c, 0x04, 0x03, 'f', 'o', 'o', 0x30, 0x05, 0x80, 0x03, 'b', 'a', 'r' };

    [pr writeFilter:@"(foo=*)"];
    uint8_t pr_bytes[] = { 0x87, 0x03, 'f', 'o', 'o' };

    [ne writeFilter:@"(!(foo=bar))"];
    uint8_t ne_bytes[] = { 0xa2, 0x0c, 0xa3, 0x0a, 0x04, 0x03, 'f', 'o', 'o', 0x04, 0x03, 'b', 'a', 'r' };

    [nl writeFilter:@"(!(foo<=bar))"];
    uint8_t nl_bytes[] = { 0xa2, 0x0c, 0xa6, 0x0a, 0x04, 0x03, 'f', 'o', 'o', 0x04, 0x03, 'b', 'a', 'r' };

    [ng writeFilter:@"(!(foo>=bar))"];
    uint8_t ng_bytes[] = { 0xa2, 0x0c, 0xa5, 0x0a, 0x04, 0x03, 'f', 'o', 'o', 0x04, 0x03, 'b', 'a', 'r' };

    [na writeFilter:@"(!(foo~=bar))"];
    uint8_t na_bytes[] = { 0xa2, 0x0c, 0xa8, 0x0a, 0x04, 0x03, 'f', 'o', 'o', 0x04, 0x03, 'b', 'a', 'r' };

    [np writeFilter:@"(!(foo=*))"];
    uint8_t np_bytes[] = { 0xa2, 0x05, 0x87, 0x03, 'f', 'o', 'o' };

    [and writeFilter:@"(&(foo=bar)(baz=banana))"];
    uint8_t and_bytes[] = { 0xa0, 0x1b,
        0xa3, 0x0a, 0x04, 0x03, 'f', 'o', 'o', 0x04, 0x03, 'b', 'a', 'r',
        0xa3, 0x0d, 0x04, 0x03, 'b', 'a', 'z', 0x04, 0x06, 'b', 'a', 'n', 'a', 'n', 'a' };
        *
 */



import 'package:unittest/unittest.dart';
import 'package:dartdap/dartdap.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

main() {


  test('Filter Encoding', () {
    // put test here.
    // foo == 66 6f 6f
    // bar = 62 61 72
    // (foo=bar)

    var a = [0xa3, 0x0a, 0x04, 0x03, 0x66, 0x6f, 0x6f, 0x04, 0x03, 0x62,0x61,0x72];
    var f = Filter.equals("foo", "bar");
    var bytes = f.toASN1().encodedBytes;
    print("a = $a \nBytes = $bytes");
    expect(a, equals(bytes));

  });
}

