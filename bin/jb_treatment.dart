import 'package:yhcjb/src/net/session.dart';
import 'package:yhcjb/yhcjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart' as xlsx;
import 'package:args/command_runner.dart';
import 'package:args/arguments_command.dart';

main(List<String> args) {
  var runner = CommandRunner('jb_treatment', '信息核对报告表和养老金计算表生成程序')
    ..addCommand(Fphd())
    ..addCommand(Download());

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

    var db = await getFpDatabase();
    var model = db.getModel<FpRawData>('2019年度扶贫办民政残联历史数据');
    for (var data in result.datas) {
      var idcard = data.idcard;
      //var date = int.parse(idcard.substring(6, 12)) + 6000;

      var records = await model.select(And([
        Eq(#idcard, idcard),
        Or.Eq(#type, ['贫困人口', '特困人员', '全额低保人员', '差额低保人员']),
        //Gte(#date, date.toString())
      ]));
      if (records.isNotEmpty) {
        print('${currentRow - startRow + 1} ${data.idcard} ${data.name}');

        var qjns = data.yjnx - data.sjnx;
        if (qjns < 0) qjns = 0;

        var record = records.first;

        sheet.copyRowTo(startRow, currentRow++, clearValue: true)
          ..cell('A').setValue(currentRow - startRow)
          ..cell('B').setValue(data.xzqh)
          ..cell('C').setValue(data.name)
          ..cell('D').setValue(data.idcard)
          ..cell('E').setValue(data.birthDay)
          ..cell('F').setValue(data.sex)
          ..cell('G').setValue(data.hjxz)
          ..cell('H').setValue(record.name)
          ..cell('I').setValue(record.type)
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

class Download extends ArgumentsCommand {
  Download()
      : super('download', description: '从业务系统下载信息核对报告表', arguments: '<date>');

  @override
  void execute(List<String> args) async {
    String date = args[0];
    getYearMonthDay(date);

    var saveXlsx = '$rootDir\\信息核对报告表$date.xlsx';

    Result<Dyfh> result;
    Session.use((session) {
      session.sendService(DyfhQuery());
      result = session.getResult<Dyfh>();
    });

    if (result.isNotEmpty) {
      var db = await getFpDatabase();
      var model = db.getModel<FpRawData>('2019年度扶贫办民政残联历史数据');
      for (var data in result.datas) {
        var idcard = data.idcard;
        //var date = int.parse(idcard.substring(6, 12)) + 6000;

        var records = await model.select(And([
          Eq(#idcard, idcard),
          Or.Eq(#type, ['贫困人口', '特困人员', '全额低保人员', '差额低保人员']),
          //Gte(#date, date.toString())
        ]));
        if (records.isNotEmpty) {
          var record = records.first;
          data.bz = '按人社厅发〔2018〕111号文办理';
          data.fpName = record.name;
          data.fpType = record.type;
        }
      }
      await db.close();

      var workbook = xlsx.Workbook.fromFile(infoXlsx);
      var sheet = workbook.sheetAt(0);
      var startRow = 4, currentRow = 4;

      for (var data in result.datas) {
        var index = currentRow - startRow + 1;
        print('$index ${data.idcard} ${data.name} ${data.bz} ${data.fpType}');
        sheet.copyRowTo(startRow, currentRow++, clearValue: true)
          ..cell('A').setValue(index)
          ..cell('B').setValue(data.name)
          ..cell('C').setValue(data.idcard)
          ..cell('D').setValue(data.xzqh)
          ..cell('E').setValue(data.payAmount)
          ..cell('F').setValue(data.payMonth)
          ..cell('G').setValue('是 [ ]')
          ..cell('H').setValue('否 [ ]')
          ..cell('I').setValue('是 [ ]')
          ..cell('J').setValue('否 [ ]')
          ..cell('K').setValue(data.bz)
          ..cell('L').setValue(data.fpType)
          ..cell('M').setValue(data.fpName);
      }
      workbook.toFile(saveXlsx);
    }
  }
}
