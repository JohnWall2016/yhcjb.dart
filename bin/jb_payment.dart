import 'package:yhcjb/src/net/session.dart';
import 'package:yhcjb/yhcjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart' as xlsx;
import 'package:commander/commander.dart';
import 'package:intl/intl.dart';

main(List<String> args) {
  Command()
    ..setDescription('财务支付单生成程序')
    ..setArguments('<ffny> [ywzt]',
        {'ffny': '发放年月, 例如: 201904', 'ywzt': '业务状态: 0-待支付(默认), 1-已支付'})
    ..setAction((Map args) {
      jbPayment(args['ffny'], args['ywzt'] ?? '0');
    })
    ..parse(args);
}

const paymentXlsx = "D:\\支付管理\\雨湖区居保个人账户返还表.xlsx";

jbPayment(String yearMonth, String state) {
  var workbook = xlsx.Workbook.fromFile(paymentXlsx);
  var sheet = workbook.sheetAt(0);

  var ymd = getYearMonth(yearMonth);
  String year = ymd[0], month = ymd[1];
  var title = '$year年$month月个人账户返还表';
  sheet.cell('A1').setValue(title);

  var date = DateFormat('yyyyMMdd').format(DateTime.now());
  var dateCh = DateFormat('yyyy年M月d日').format(DateTime.now());
  var reportDate = '制表时间：$dateCh';
  sheet.cell('H2').setValue(reportDate);

  Session.use((session) {
    var startRow = 5, currentRow = 5;
    num sum = 0;

    session.sendService(CwzfglQuery(yearMonth, state));
    var result = session.getResult<Cwzfgl>();

    for (var data in result.datas) {
      if (data.type == '3') {
        session.sendService(CwzfglZfdryQuery(
            paymentNO: '${data.paymentNO}',
            yearMonth: '${data.yearMonth}',
            state: '${data.state}',
            paymentType: '${data.paymentType}'));
        var zfdryResult = session.getResult<CwzfglZfdry>();
        var payment = zfdryResult[0];

        String reason, bankName;
        session.sendService(DyzzfhPerInfoListQuery(payment.idcard));
        var infoListResult = session.getResult<DyzzfhPerInfoList>();
        var infoList = infoListResult[0];
        if (infoList != null) {
          session.sendService(DyzzfhPerInfoQuery(infoList));
          var infoResult = session.getResult<DyzzfhPerInfo>();
          var info = infoResult[0];
          if (info != null) {
            reason = info.reasonCh;
            bankName = info.bankName;
          }
        } else {
          session.sendService(CbzzfhPerInfoListQuery(payment.idcard));
          var infoListResult = session.getResult<CbzzfhPerInfoList>();
          var infoList = infoListResult[0];
          if (infoList != null) {
            session.sendService(CbzzfhPerInfoQuery(infoList));
            var infoResult = session.getResult<CbzzfhPerInfo>();
            var info = infoResult[0];
            if (info != null) {
              reason = info.reasonCh;
              bankName = info.bankName;
            }
          }
        }

        var row = sheet.copyRowTo(startRow, currentRow++, clearValue: true)
          ..cell('A').setValue(currentRow - startRow)
          ..cell('B').setValue(payment.name)
          ..cell('C').setValue(payment.idcard);

        var type = payment.paymentTypeCh;
        if (reason != null) {
          type = '$type($reason)';
        }

        var amount = payment.paidAmount;
        row
          ..cell('D').setValue(type)
          ..cell('E').setValue(payment.payList)
          ..cell('F').setValue(amount)
          ..cell('G').setValue(getMoneyCh(amount))
          ..cell('H').setValue(data.paidName)
          ..cell('I').setValue(data.paidAccount)
          ..cell('J').setValue(bankName);

        sum += amount;
      }
    }
    sheet.copyRowTo(startRow, currentRow)
      ..cell('A').setValue('合计')
      ..cell('F').setValue(sum);

    workbook.toFile(appendToFileName(paymentXlsx, date));
  });
}
