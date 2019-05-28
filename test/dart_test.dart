import 'dart:io';

import 'package:yhcjb/yhcjb.dart';

main() {
  /*
  const rylx = {
    'pkry': ['贫困人口', '特困人员', '全额低保人员', '差额低保人员'],
    'cjry': ['一二级残疾人员', '三四级残疾人员']
  };

  print(rylx.values.expand((list) => list));
  */

  /*print(tmpDir());
  print(randomString(6));
  print(tmpName());*/
  /*var path = temporaryFilePath();
  print(path);
  print(File(path).path);*/

  //print(getFormatDate());
  /*print(1 / 2);
  print(1 ~/ 2);*/

  var man = ['John', 'Peter'];
  var people = ['Rose', ...man];
  print(people);

  print(Platform.localeName);
}

class M1 {
  num field;
}

class M2 {
  num field;
}

class C with M1, M2 {

}
