



import "dart:async";



main() async {

  Stream<int> foo() async* {
    yield 1;
    yield 6;

  }


  await for( var i in foo() ) {
    print(i );
  }


}