import 'package:yhcjb/src/json/json.dart';

main() {
  testJson();
}

class IdName extends Jsonable {
  int id;
  String name;
}

class Education extends Jsonable {
  String name;
  String school;

  Education();
  Education._(this.name, this.school);
}

abstract class Relations {
  List relations = ['John', 'Peter'];
}

class Employee extends IdName with Relations {
  String position;
  double salary;

  List skills;

  List<Education> educations;

  List records = [];

  List relations = ['Joe', 'Rose'];
}

testJson() {
  var emp = Employee()
    ..id = 1
    ..name = 'Joseph'
    ..position = 'CEO'
    ..salary = 1000000
    ..skills = ['negotiation', 'programming', 'accounting']
    ..educations = [
      Education._('HS', 'ABC'), Education._('BA', 'MIT')
    ]
    ..records.add({'2018': 'IBM'});

  var json = emp.toJson();
  print(json);

  emp = Jsonable.fromJson<Employee>(json);
  print(emp.skills);
  emp.educations.forEach((e) => print('${e.name} ${e.school}'));
  print(emp.records);
  print(emp.relations);
}