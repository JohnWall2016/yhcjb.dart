import 'package:yhcjb/yhcjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart';

main(List<String> args) {
  //var runner = CommandRunner('fp_data', '扶贫数据导库比对程序')..addCommand();

  //runner.run(args);
}

fetchPkData({String date, String xlsx, int beginRow, int endRow}) sync* {
  var workbook = Workbook.fromFile(xlsx);
  var sheet = workbook.sheetAt(0);

  for (var index = beginRow; index <= endRow; index++) {
    var row = sheet.rowAt(index);
    if (row != null) {
      String name = row.cell('H').value();
      String idcard = row.cell('I').value();
      String birthDay = idcard.substring(6, 14);
      String xzj = row.cell('C').value();
      String csq = row.cell('D').value();

      yield FpRawData()
        ..name = name
        ..idcard = idcard
        ..birthDay = birthDay
        ..xzj = xzj
        ..csq = csq
        ..type = '贫困人口'
        ..detail = '是'
        ..date = date;
    }
  }
}
