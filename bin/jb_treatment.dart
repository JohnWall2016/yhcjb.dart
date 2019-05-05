import 'package:yhcjb/yhcjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart' as xlsx;

main(List<String> args) {
  var runner = CommandRunner('jb_treatment', '信息核对报告表和养老金计算表生成程序')
    ..addCommand(new Fphd());

  runner.run(args);
}

const rootDir = 'D:\\待遇核定';
const infoXlsx = '${rootDir}\\信息核对报告表模板.xlsx';
const payInfoXslx = '${rootDir}\\养老金计算表模板.xlsx';
const fphdXlsx = '${rootDir}\\到龄贫困人员待遇核定情况表模板.xlsx';

class Fphd extends ArgumentsCommand {
  Fphd()
      : super('fphd',
            description: '从业务系统下载生成到龄贫困人员待遇核定情况表', arguments: '<date>');

  @override
  void execute(List<String> args) async {
    String date = args[0];
    String dlny = getYearMonthDay(date)[3];
    var saveXlsx = '${rootDir}\\到龄贫困人员待遇核定情况表(截至${date}).xlsx';

    var workbook = xlsx.Workbook.fromFile(fphdXlsx);
    var sheet = workbook.sheetAt(0);
    var startRow = 4, currentRow = 4;

    Result<Dyry> result;
    Session.use((session) {
      session.sendService(DyryQuery(dlny: dlny));
      result = session.getResult();
    });

    var db = await getDbConnection();
    for (var data in result.datas) {
      var idcard = data.idcard;
      //var date = int.parse(idcard.substring(6, 12)) + 6000;

      var dbResult = await db.query(
          'select 姓名, 人员类型 from 2019年度扶贫办民政残联历史数据 '
          'where 身份证号码 = ? and '
          '     (人员类型 = \'贫困人口\' or '
          '      人员类型 = \'特困人员\' or '
          '      人员类型 = \'全额低保人员\' or '
          '      人员类型 = \'差额低保人员\')'
          /*'  and 数据月份 >= ?'*/,
          [idcard/*, date.toString()*/]);

      if (dbResult.isNotEmpty) {
        print('${currentRow - startRow + 1} ${data.idcard} ${data.name}');

        var qjns = data.yjnx - data.sjnx;
        if (qjns < 0) qjns = 0;

        sheet.copyRowTo(startRow, currentRow++, clearValue: true)
          ..cell('A').setValue(currentRow - startRow)
          ..cell('B').setValue(data.xzqh)
          ..cell('C').setValue(data.name)
          ..cell('D').setValue(data.idcard)
          ..cell('E').setValue(data.birthDay)
          ..cell('F').setValue(data.sex)
          ..cell('G').setValue(data.hjxz)
          ..cell('H').setValue(dbResult.first[0])
          ..cell('I').setValue(dbResult.first[1])
          ..cell('J').setValue(data.jbzt)
          ..cell('K').setValue(data.lqny)
          ..cell('L').setValue(data.yjnx)
          ..cell('M').setValue(data.sjnx)
          ..cell('N').setValue(qjns)
          ..cell('O').setValue(data.qbzt)
          ..cell('P').setValue(data.bz);
      }
    }
    await db.close();
    workbook.toFile(saveXlsx);
  }
}
