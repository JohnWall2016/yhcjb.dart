import 'dart:io';
import 'dart:math' as math;
import 'dart:mirrors';

import 'package:decimal/decimal.dart';
import 'package:yhcjb/yhjb.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import 'package:icu4dart/icu4dart.dart';

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
/*
  var man = ['John', 'Peter'];
  var people = ['Rose', ...man];
  print(people);

  print(Platform.localeName);

  print(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));

  print('--abc, no-ccc'.replaceAll(RegExp('--|no-'), ''));

  //print(''.substring(2));
  print('aaa-bbb-ccc'.split('-').reduce((v, e) {
    if (e != null && e.isNotEmpty) {
      return v + e[0].toUpperCase() + e.substring(1);
    }
  }));

  List<String> a;

  print(<String>[...(a ?? []), ''].map((s) => s.length).reduce(math.max));
  print(<String>[].map((s) => s).join(' ') == '');

  print(p.basenameWithoutExtension(Platform.script.path));

  print(FunctionWithMap is Function);
  print(fn is FunctionWithMap);
*/
/*  
  print(reflectType(103.runtimeType).isAssignableTo(reflectType(num)));

  num n = 10;
  n += 1.1;
  print(n);

  print(getMoneyCh(12325002652306.01));
*/
/*
  var collator = Collator('zh');
  var list = [
    "长城乡",
    "昭潭街道",
    "先锋街道",
    "万楼街道",
    "楠竹山镇",
    "姜畲镇",
    "鹤岭镇",
    "城正街街道",
    "雨湖路街道",
    "云塘街道",
    "窑湾街道",
    "广场街道"
  ];
  print(list);
  list.sort((first, second) => collator.compare(first, second));
  print(list);
  collator.close();
*/
/*
  var s = '长城乡';

  for (var c in s.split('')) {
    print(c);
  }

  for (var c in s.codeUnits) {
    print(c);
  }

  var len = s.length;
  print(len);

  for (var i = 0; i < len; i++) {
    print(s[i]);
  }
*/
  //print(getMoneyCh(Decimal.parse('1046.61')));

/*
  print(1024.61 * 100);
  print((1024.62 * 100).toInt());
*/
  'Hello World'.put();
}

extension StringEx on String {
  void put() => print(this);
}

typedef FunctionWithMap = dynamic Function(Map<String, String> args);
typedef FunctionWithList = dynamic Function(List args);

void fn(Map args) {

}

class M1 {
  num field;
}

class M2 {
  num field;
}

class C with M1, M2 {

}
