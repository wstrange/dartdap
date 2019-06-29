import 'package:test/test.dart';
import 'package:dartdap/dartdap.dart';
import 'package:petitparser/debug.dart';

main() {
  test("Basic Parser test", () {
    var babs = Filter.equals("cn", "Babs");
    var foo = Filter.equals("sn", "Foo");

    Map<String, Filter> m = {
      '(cn=Babs)': babs,
      '(&(cn=Babs)(sn=Foo))': Filter.and([babs, foo]),
    //  '(sn=Foo*)': Filter.substring("sn", "Foo*"),
      '(sn=*Foo)': Filter.substring("sn", "*Foo"),
      '(sn=*Foo*Baz*)': Filter.substring("sn", '(sn=*Foo*Baz*)')
    };

    m.forEach((query, filter) {
      //var result = trace(queryParser).parse(query);
      var result = queryParser.parse(query);

      expect(result.isSuccess, true,
          reason: "parsing error was: ${result.message}");
      expect(result.value, equals(filter));
      print("Result = ${result.value}");
    });
  });
}
