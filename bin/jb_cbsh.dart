import 'package:yhcjb/yhcjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart' as xlsx;
import 'package:path/path.dart' as p;

const jbsfMap = {
  '贫困人口一级': '051',
  '特困一级': '031',
  '低保对象一级': '061',
  '低保对象二级': '062',
  '残一级': '021',
  '残二级': '022'
};

usage() {
  print(r'usage:   dart bin\jb_cbsh.dart 开始审核时间 [结束审核时间]');
  print(r'example: dart bin\jb_cbsh.dart 20190429 20190505');
}

main(List<String> args) async {
  String dir = r'D:\精准扶贫\';
  String template = '批量信息变更模板.xlsx';

  if (args.isEmpty) {
    usage();
    return;
  }

  String qsshsj, jsshsj;
  try {
    qsshsj = getYearMonthDay(args[0])[3];
    if (args.length > 1) jsshsj = getYearMonthDay(args[1])[3];
  } catch (error) {
    usage();
    return;
  }

  print('$qsshsj${jsshsj != null ? ' ' + jsshsj : ''}');

  Result<Cbsh> result;
  Session.use((session) {
    session.sendService(CbshQuery(qsshsj: qsshsj, jzshsj: jsshsj, shzt: '1'));
    result = session.getResult<Cbsh>();
  });

  if (result.length > 0) {
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

        xlsx.Row xrow;
        if (index == copyIndex)
          xrow = sheet.rowAt(index);
        else
          xrow = sheet.insertRowCopyFrom(index, copyIndex);
        xrow.cell('A').setValue(cbsh.idcard);
        xrow.cell('C').setValue(cbsh.name);
        xrow.cell('H').setValue(jbsfMap[row[2]]);

        index++;
      }

      await conn.close();
    }
    workbook.toFile(p.join(dir,
        '批量信息变更模板' + qsshsj + (jsshsj != null ? '_' + jsshsj : '') + '.xlsx'));
  }
}
