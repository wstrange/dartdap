

//import 'dart:async';

foo() async => 42;

test() async {
  int x = (await foo());
  print( "x=$x");
}

main() async {

  await test();
  int x = (await foo());
   print( "x=$x");

}