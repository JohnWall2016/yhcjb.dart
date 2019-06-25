import 'package:yhcjb/yhcjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart' as xlsx;
import 'package:commander/commander.dart';

main(List<String> args) {
  var program = Command()..setDescription('信息查询程序');

  program.command('doc')
    ..setDescription('档案目录生成')
    ..setArguments('<xlsx>', {'xlsx': 'xlsx文件'})
    ..setAction((List args) => doc(args));

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
      session.sendService(GrinfoQuery(idcard));
      var result = session.getResult<Grinfo>();
      row.cell('D').setValue('${result[0].name}制度衔接转出相关资料');
    }
  });

  workbook.toFile(appendToFileName(file, '.upd'));
}