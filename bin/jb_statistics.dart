import 'package:xlsx_decoder/xlsx_decoder.dart';
import 'package:commander/commander.dart';
import 'package:yhcjb/yhcjb.dart';

main(List<String> args) {
  var program = Command()..setDescription('统计程序');
  
  program.command('xzqh')
    ..setDescription('根据行政区划统计总数')
    ..setArguments('<xlsx> <beginRow> <endRow> <xzqhRow>', {

    })
    ..setAction(count);

  program.parse(args);
}

count(List args) {
  var xlsx = args[0];
  var beginRow = int.parse(args[1]);
  var endRow = int.parse(args[2]);
  var xzqhRow = args[3];

  var workbook = Workbook.fromFile(xlsx);
  var sheet = workbook.sheetAt(0);
  var map = <String, int>{};
  var count = 0;
  for (var i = beginRow; i <= endRow; i++) {
    var row = sheet.rowAt(i);
    String xzqh = row.cell(xzqhRow).value();
    Match m;
    for (var regex in reXzhq) {
      m = RegExp(regex).firstMatch(xzqh);
      if (m != null) break;
    }
    if (m == null) {
      stop('未匹配行政区划: $xzqh');
    } else {
      var xzj = m[2];
      if (map.containsKey(xzj)) {
        map[xzj] += 1;
      } else {
        map[xzj] = 1;
      }
      count ++;
    }
  }
  map['合计'] = count;
  for (var xzj in map.keys) {
    print('$xzj${''.padRight(14-xzj.length*2, ' ')} ${map[xzj]}');
  }
}