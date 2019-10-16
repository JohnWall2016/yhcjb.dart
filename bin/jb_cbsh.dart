import 'package:yhcjb/yhjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart' as xlsx;
import 'package:path/path.dart' as p;
import 'package:commander/commander.dart';
import 'dart:io';

const jbsfMap = {
  '贫困人口一级': '051',
  '特困一级': '031',
  '低保对象一级': '061',
  '低保对象二级': '062',
  '残一级': '021',
  '残二级': '022'
};

main(List<String> args) {
  Command()
    ..setDescription('特殊参保人员身份信息变更导出程序')
    ..setArguments('<qsshsj> [jzshsj]',
        {'qsshsj': '起始审核时间, 例如: 20190429', 'jzshsj': '截至审核时间, 例如: 20190505'})
    ..setAction((Map args) {
      String qsshsj = args['qsshsj'];
      String jzshsj = args['jzshsj'];
      jbCbsh(qsshsj, jzshsj);
    })
    ..parse(args);
}

jbCbsh(String qsshsj, String jzshsj) async {
  String dir = r'D:\精准扶贫\';
  String template = '批量信息变更模板.xlsx';

  try {
    qsshsj = getYearMonthDay(qsshsj)[3];
    if (jzshsj != null) {
      jzshsj = getYearMonthDay(jzshsj)[3];
    }
  } catch (error) {
    print(error);
    return;
  }

  print('$qsshsj${jzshsj != null ? ' ' + jzshsj : ''}');

  Result<Cbsh> result;
  Session.use((session) {
    session.sendService(
        CbshQuery(qsshsj: qsshsj, jzshsj: jzshsj ?? '', shzt: '1'));
    result = session.getResult<Cbsh>();
  });

  var export = false;
  var len = result.length;
  print(len);
  if (len > 0) {
    var workbook = xlsx.Workbook.fromFile(p.join(dir, template));
    var sheet = workbook.sheetAt(0);
    int index = 2, copyIndex = 2;
    for (Cbsh cbsh in result.datas) {
      print('${cbsh.idcard} ${cbsh.name} ${cbsh.birthday}');

      var conn = await getDbConnection();

      var results = await conn.query(
          'select 姓名, 身份证号码, 居保认定身份 from 2019年度扶贫历史数据底册 where 身份证号码 = ?',
          [cbsh.idcard]);
      for (var row in results) {
        print(row);
        export = true;

        sheet.copyRowTo(copyIndex, index++, clearValue: false)
          ..cell('A').setValue(cbsh.idcard)
          ..cell('C').setValue(cbsh.name)
          ..cell('H').setValue(jbsfMap[row[2]]);
      }

      await conn.close();
    }
    if (export) {
      var path = p.join(dir,
          '批量信息变更模板' + qsshsj + (jzshsj != null ? '_' + jzshsj : '') + '.xlsx');
      var file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
      workbook.toFile(path);
    }
  }
}
