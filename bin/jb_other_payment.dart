import 'package:yhcjb/yhjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart' as xlsx;
import 'package:commander/commander.dart';
import 'package:intl/intl.dart';
import 'package:icu4dart/icu4dart.dart';

main(List<String> args) {
  var program = Command()..setDescription('代发数据导出制表程序');

  program.command('personList')
    ..setDescription('正常代发人员名单导出')
    ..setArguments('<type> <date>', {
      'type': '代发类型: 801 - 独生子女, 802 - 乡村教师, 803 - 乡村医生, 807 - 电影放映员',
      'date': '代发年月: 格式 YYYYMM, 如 201901'
    })
    ..setAction((List args) => personList(args));

  program.command('payList')
    ..setDescription('代发支付明细导出')
    ..setArguments('<type> <date>', {
      'type':
          '业务类型: DF0001 - 独生子女, DF0002 - 乡村教师, DF0003 - 乡村医生, DF0007 - 电影放映员',
      'date': '支付年月: 格式 YYYYMM, 如 201901'
    })
    ..setAction((List args) => payList(args));

  program.parse(args);
}

const personListXlsx = 'D:\\代发管理\\雨湖区城乡居民基本养老保险代发人员名单.xlsx';

void personList(List args) async {
  String type = args[0];
  String yearMonth = args[1];

  var workbook = xlsx.Workbook.fromFile(personListXlsx);
  var sheet = workbook.sheetAt(0);

  var startRow = 4, currentRow = 4;
  num sum = 0;

  var date = DateFormat('yyyyMMdd').format(DateTime.now());
  var dateCh = DateFormat('yyyy年M月d日').format(DateTime.now());
  var reportDate = '制表时间：$dateCh';

  sheet.cell('G2').setValue(reportDate);

  Session.use((session) {
    session.sendService(DfrymdQuery(type, '1', '1'));
    var result = session.getResult<Dfrymd>();
    result.datas.forEach((data) {
      if (data.grbh == null) return;
      num payAmount = 0;
      if (data.standard != null) {
        var startYear = data.startYearMonth ~/ 100;
        var startMonth = data.startYearMonth % 100;
        startMonth -= 1;
        if (startMonth == 0) {
          startYear -= 1;
          startMonth = 12;
        }
        if (data.endYearMonth != null) {
          startYear = data.endYearMonth ~/ 100;
          startMonth = data.endYearMonth % 100;
        }
        var match = RegExp(r'^(\d\d\d\d)(\d\d)$').firstMatch(yearMonth);
        if (match != null) {
          var endYear = int.parse(match.group(1));
          var endMonth = int.parse(match.group(2));
          payAmount = ((endYear - startYear) * 12 + endMonth - startMonth) *
              data.standard;
        }
      } else if (data.totalSum == 5000) {
        return;
      }

      sheet.copyRowTo(startRow, currentRow++, clearValue: true)
        ..cell('A').setValue(currentRow - startRow)
        ..cell('B').setValue(data.region)
        ..cell('C').setValue(data.name)
        ..cell('D').setValue(data.idcard)
        ..cell('E').setValue(data.startYearMonth)
        ..cell('F').setValue(data.standard)
        ..cell('G').setValue(data.type)
        ..cell('H').setValue(data.jbStateChn)
        ..cell('I').setValue(data.endYearMonth)
        ..cell('J').setValue(data.totalSum)
        ..cell('K').setValue(payAmount);

      sum += payAmount;
    });
  });

  sheet.copyRowTo(startRow, currentRow, clearValue: true)
    ..cell('A').setValue('')
    ..cell('C').setValue('共计')
    ..cell('D').setValue(currentRow - startRow)
    ..cell('F').setValue('')
    ..cell('J').setValue('合计')
    ..cell('K').setValue(sum);

  workbook.toFile(
      appendToFileName(personListXlsx, '(${Dfrymd.getTypeName(type)})$date'));
}

const payListXlsx = 'D:\\代发管理\\雨湖区城乡居民基本养老保险代发人员支付明细.xlsx';

class PayListItem {
  String region;
  String name;
  String idcard;
  String type;
  int yearMonth;
  int startPensionDate;
  int endPensionDate;
  num payAmount;

  String toString() =>
      '$region $name $idcard $type $yearMonth $startPensionDate $endPensionDate $payAmount';
}

void payList(List args) async {
  var exportItems = <PayListItem>[];

  String type = args[0];
  String yearMonth = args[1];

  num totalSum = 0;
  var typeChn = Dfpayffzfdj.otherPayTypeChn(type);

  Session.use((session) {
    session.sendService(DfpayffzfdjQuery(type, yearMonth));
    var zfdjResult = session.getResult<Dfpayffzfdj>();
    zfdjResult.datas.forEach((zfdj) {
      if (zfdj.typeChn != null && zfdj.typeChn != '') {
        session.sendService(DfpayffzfdjmxQuery(zfdj.payList));
        var zfdjmxResult = session.getResult<Dfpayffzfdjmx>();
        zfdjmxResult.datas.forEach((zfdjmx) {
          if (zfdjmx.region != null &&
              zfdjmx.region != '' &&
              zfdjmx.flag == '0') {
            session.sendService(DfpayffzfdjgrmxQuery(
                zfdjmx.grbh, zfdjmx.payList, zfdjmx.perPayList));
            var grmxResult = session.getResult<Dfpayffzfdjgrmx>();
            int startPensionDate, endPensionDate;
            var count = grmxResult.length;
            if (count > 0) {
              startPensionDate = grmxResult[0].pensionDate;
              if (count > 2) {
                endPensionDate = grmxResult[count - 2].pensionDate;
              } else {
                endPensionDate = startPensionDate;
              }
            }
            totalSum += zfdjmx.payAmount;
            exportItems.add(PayListItem()
              ..region = zfdjmx.region
              ..name = zfdjmx.name
              ..idcard = zfdjmx.idcard
              ..type = typeChn
              ..yearMonth = zfdjmx.yearMonth
              ..startPensionDate = startPensionDate
              ..endPensionDate = endPensionDate
              ..payAmount = zfdjmx.payAmount);
          }
        });
      }
    });
  });

  var collator = Collator('zh');
  exportItems.sort((a, b) {
    var r = collator.compare(a.region, b.region);
    if (r == 0) {
      r = collator.compare(a.name, b.name);
    }
    return r;
  });
  collator.close();

  var workbook = xlsx.Workbook.fromFile(payListXlsx);
  var sheet = workbook.sheetAt(0);
  var startRow = 4, currentRow = 4;

  var date = DateFormat('yyyyMMdd').format(DateTime.now());
  var dateCh = DateFormat('yyyy年M月d日').format(DateTime.now());
  var reportDate = '制表时间：$dateCh';
  sheet.cell('G2').setValue(reportDate);

  for (var item in exportItems) {
    sheet.copyRowTo(startRow, currentRow++, clearValue: true)
      ..cell('A').setValue(currentRow - startRow)
      ..cell('B').setValue(item.region)
      ..cell('C').setValue(item.name)
      ..cell('D').setValue(item.idcard)
      ..cell('E').setValue(item.type)
      ..cell('F').setValue(item.yearMonth)
      ..cell('G').setValue(item.startPensionDate)
      ..cell('H').setValue(item.endPensionDate)
      ..cell('I').setValue(item.payAmount);
  }
  sheet.copyRowTo(startRow, currentRow, clearValue: true)
    ..cell('C').setValue('共计')
    ..cell('D').setValue(currentRow - startRow)
    ..cell('H').setValue('合计')
    ..cell('I').setValue(totalSum);
  workbook.toFile(appendToFileName(payListXlsx, '($typeChn)$date'));
}
