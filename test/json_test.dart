import 'dart:convert';

import 'package:yhcjb/src/json/json.dart';

main(List<String> args) {
  testJson2();
}

testJson() {
  var map = <String, dynamic>{
    'null': null,
    'bool': true,
    'int': 1,
    'double': 2.0,
    'String': 'hello',
    'List': [1, 2, 4],
  };
  var out = json.encode(map);
  print(out);
  var input = json.decode(out);
  print(input.runtimeType);
  (input as Map<String, dynamic>).forEach((key, value) {
    print('${key}\'s type: ${value.runtimeType}');
  });
  print(input);
}

class Person extends Jsonable<Person> {
  String name;
  int age;

  Person.create(this.name, this.age);
  Person();
}

class Test extends Jsonable<Test> {
  dynamic d;
  int i = 1;
  double db = 2.0;

  @Json(name: 'greeting')
  String str = 'hello';

  //@Json(ignored: true)
  List<Person> list = <Person>[Person.create('Peter', 40)];

  Person person = Person.create('John', 23);
}

testJson2() {
  //print(json.encode(Test()));
  var test = Test();
  test.person.name = 'John2';
  test.list[0].name = 'Peter3';
  var map = test.toMap();
  print(map);
  var str = json.encode(map);
  print(str);
  map = json.decode(str);
  print(map);
  print(map['person'].runtimeType);
  var test2 = Jsonable.fromMap<Test>(map);
  print(test2.person.name);
  print(test2.list[0].name);

  var ldh = Jsonable.fromJson<Person>('''{
    "name": "LDH",
    "age": 56
  }''');

  print(ldh.name);
  print(ldh.age);

  print(ldh.toJson());

  var test3 = Jsonable.fromJson<Test>('{"d":null,"i":2,"db":3.0,"greeting":"hello2","list":[{"name":"Peter4","age":402}],"person":{"name":"John5","age":223}}');

  print(test3.toJson());
}