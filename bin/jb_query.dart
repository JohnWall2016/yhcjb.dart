import 'package:yhcjb/yhcjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart' as xlsx;
import 'package:commander/commander.dart';

main(List<String> args) {
  var program = Command()..setDescription('信息查询程序');

  program.command('doc')
    ..setDescription('档案目录生成')
    ..setArguments('<xlsx>', {'xlsx': 'xlsx文件'})
    ..setAction((List args) => doc(args));

  program.command('inherit')
    ..setDescription('死亡继承表格更新程序')
    ..setArguments('<xlsx> <beginRow> <endRow>')
    ..setAction((List args) => inherit(args));

  program.parse(args);

}

doc(List args) {
  var file = args[0];
  var workbook = xlsx.Workbook.fromFile(file);
  var sheet = workbook.sheetAt(0);

  Session.use((session) {
    for (var i = 1; i <= sheet.lastRowIndex; i++) {
      var row = sheet.rowAt(i);
      String idcard = row.cell('A').value();
      String title = row.cell('D').value();
      session.sendService(SncbxxConQuery(idcard));
      var result = session.getResult<SncbxxCon>();
      if (result.isNotEmpty) {
        row.cell('E').setValue('${result[0].name}$title');
      }
    }
  });

  workbook.toFile(appendToFileName(file, '.upd'));
}

inherit(List args) {
  var file = args[0];
  var start = int.parse(args[1]);
  var end = int.parse(args[2]);

  var workbook = xlsx.Workbook.fromFile(file);
  var sheet = workbook.sheetAt(0);

  Session.use((session) {
    for (var i = start; i <= end; i++) {
      var row = sheet.rowAt(i);
      String idcard = row.cell('B').value();
      
      print('$row $idcard');

      session.sendService(GrinfoQuery(idcard));
      var result = session.getResult<Grinfo>();
      if (result.isNotEmpty) {
        var info = result.datas[0];

        print('${info.czmc}|${info.dwmc}|${info.jbzt}');

        row.cell('C').setValue(info.name);
        row.cell('E').setValue(info.czmc);
        row.cell('F').setValue(info.dwmc);
        row.cell('G').setValue(info.jbzt);

        var deathTime = row.cell('D').value();

        session.sendService(PausePaymentQuery(idcard));
        var result2 = session.getResult<PausePayment>();
        if (result2.isNotEmpty) {
          var pause = result2.datas[0];

          print('${pause.idcard}|${pause.name}|${pause.time}|${pause.reasonChn}|${pause.memo}');

          row.cell('H').setValue('暂停');
          var pauseTime = pause.time;
          row.cell('I').setValue(pauseTime);

          try {
            var delta = substractMonth(int.parse(deathTime), previousMonth(pauseTime));

            print('${deathTime} - ${pauseTime} + 1 = ${delta}');

            row.cell('J').setValue(delta);
          } catch (err) {
            print('无法计算时间差, ${deathTime} - ${pauseTime}: ${err}');
          }
          row.cell('K').setValue(pause.reasonChn);
          row.cell('L').setValue(pause.memo);
        }

        session.sendService(SuspiciousDeathQuery(idcard));
        var result3 = session.getResult<SuspiciousDeath>();
        if (result3.isNotEmpty) {
          var sdeath = result3.datas[0];
          var sdeathTime = sdeath.deathTime ~/ 100;
          row.cell('M').setValue(deathTime);
          try {
            var delta = substractMonth(deathTime, sdeathTime);

            print('${deathTime} - ${sdeathTime} = ${delta}');

            row.cell('N').setValue(delta);
          } catch (err) {
            print('无法计算时间差, ${deathTime} - ${sdeathTime}: ${err}');
          }
        }
      }
    }
  });

  workbook.toFile(appendToFileName(file, '.upd'));
}
