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
        '(|(cn=Babs)(sn=Foo))': Filter.or([babs,foo]),
      '(sn=Foo*)': SubstringFilter.rfc224("sn", initial: "Foo"),
      '(sn=*Foo)': SubstringFilter.rfc224("sn", finalValue: "Foo"),
      '(sn=*Foo*Baz*)': SubstringFilter.rfc224("sn", any: ["Foo","Baz"]),
      '(!(sn=Foo*))':
      Filter.not(SubstringFilter.rfc224("sn", initial: "Foo",)),
      '(|(cn=Babs)(sn=Foo))' : Filter.or([babs,foo]),
      '(sn~=Foo)' : Filter.approx("sn", "Foo"),
      // A complex compound filter
      '(&(cn=Babs)(|(cn=Babs)(sn=Foo)))':
          Filter.and( [babs, Filter.or([babs, foo])]),


     //Fails - parses as SubstringFilter:<SubstringFilter(_init=null, any=*, fin=null)>
      '(cn=*)' : Filter.present("cn"),

    };

    m.forEach((query, filter) {
      print("eval: $query");
      //var result = trace(queryParser).parse(query);

       var result = queryParser.parse(query);

//      expect(result.isSuccess, true,
//          reason: "parsing error was: ${result.message}");
      expect(result.value, equals(filter));
      // print("Result = ${result.value}");
    });
  });
}
