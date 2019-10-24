import 'package:xlsx_decoder/xlsx_decoder.dart' as xlsx;
import 'package:path/path.dart' as p;
import 'package:commander/commander.dart';
import 'package:yhcjb/util.dart';
import 'package:decimal/decimal.dart';

main(List<String> args) {
  Command()
    ..setDescription('记账凭证生成程序')
    ..setArguments('<xlsx> <beginRow> <endRow>',
        {'xlsx': '凭证记录XLSX文件', 'beginRow': '开始行', 'endRow': '结束行'})
    ..setAction((List args) => generateJzpz(args))
    ..parse(args);
}

class Jzpz {
  String zy, jfkm, dfkm, pzzs, rq, kjzg, jz, sh, zd, cn;
  num jfje, dfje;
  int bh;

  String get date {
    var ymd = getYearMonthDay(rq);
    return '${ymd[0]}年${ymd[1]}月${ymd[2]}日';
  }

  String get hj {
    return getMoneyCh(Decimal.parse(jfje.toStringAsFixed(2)));
  }
}

generateJzpz(List args) {
  String inXslx = args[0];
  int start = int.parse(args[1]);
  int end = int.parse(args[2]);

  String tmplXlsx = r'D:\工会工作\记账凭证生成\excel会计记账凭证模板表.xlsx';
  String outDir = r'D:\工会工作\记账凭证生成\生成目录';
  int numPerPage = 3;

  var workbook = xlsx.Workbook.fromFile(inXslx);
  var sheet = workbook.sheetAt(0);

  var list = <Jzpz>[];
  for (var index = start; index <= end; index++) {
    var row = sheet.rowAt(index);
    var jzpz = Jzpz();
    jzpz
      ..bh = row.cell('A').value()
      ..zy = row.cell('B').value()
      ..jfkm = row.cell('C').value()
      ..jfje = row.cell('D').value()
      ..dfkm = row.cell('E').value()
      ..dfje = row.cell('F').value()
      ..pzzs = row.cell('G').value()
      ..rq = row.cell('H').value()
      ..kjzg = row.cell('I').value()
      ..jz = row.cell('J').value()
      ..sh = row.cell('K').value()
      ..zd = row.cell('L').value()
      ..cn = row.cell('M').value();
    list.add(jzpz);
  }

  var length = list.length;
  var pages = length ~/ numPerPage;
  if (length % numPerPage > 0) {
    pages += 1;
  }
  for (var page = 0; page < pages; page++) {
    print('生成第${page+1}页');
    var workbook = xlsx.Workbook.fromFile(tmplXlsx);
    var sheet = workbook.sheetAt(0);
    for (var i = 0; i < numPerPage; i++) {
      var no = page * numPerPage + i;
      if (no < length) {
        sheet.rowAt(3 + i * 11)
            .cell('A').setValue(list[no].date);
        sheet.rowAt(4 + i * 11)
            .cell('S').setValue(list[no].bh);
        sheet.rowAt(5 + i * 11)
            .cell('AA').setValue('附凭证 ${list[no].pzzs} 张');
        sheet.rowAt(6 + i * 11)
            ..cell('A').setValue(list[no].zy)
            ..cell('B').setValue(list[no].jfkm)
            ..cell('C').setValue(list[no].jfje);
        sheet.rowAt(7 + i * 11)
            ..cell('B').setValue(list[no].dfkm)
            ..cell('N').setValue(list[no].dfje);
        sheet.rowAt(10 + i * 11)
            ..cell('A').setValue('    合计：${list[i].hj}')
            ..cell('C').setValue(list[no].jfje)
            ..cell('N').setValue(list[no].dfje);
        sheet.rowAt(11 + i * 11)
            ..cell('A').setValue(
              '会计主管：${list[no].kjzg}       记账：${list[no].jz}          ' +
              '审核：${list[no].sh}       制单：${list[no].zd}        出纳：${list[no].cn}'
            );
      }
    }
    workbook.toFile(p.join(outDir, '第${page+1}页凭证.xlsx'));
  }
}
