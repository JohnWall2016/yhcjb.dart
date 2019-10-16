import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yhcjb/yhjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart' as xlsx;
import 'package:commander/commander.dart';
import 'package:intl/intl.dart';

main(List<String> args) {
  var program = Command()..setDescription('信息核对报告表和养老金计算表生成程序');

  program.command('fphd')
    ..setDescription('从业务系统下载生成到龄贫困人员待遇核定情况表')
    ..setArguments('<date>', {'date': '截至到龄日期，格式：yyyymmdd'})
    ..setAction((List args) => fphd(args));

  program.command('download')
    ..setDescription('从业务系统下载信息核对报告表')
    ..setArguments('<date>', {'date': '报表生成日期，格式：yyyymmdd'})
    ..setAction((List args) => download(args));

  program.command('split')
    ..setDescription('对下载的信息表分组并生成养老金计算表')
    ..setArguments('<date> <beginRow> <endRow>', {'date': '报表生成日期，格式：yyyymmdd'})
    ..setAction((List args) => split(args));

  program.parse(args);
}

const rootDir = 'D:\\待遇核定';
const infoXlsx = '${rootDir}\\信息核对报告表模板.xlsx';
const payInfoXslx = '${rootDir}\\养老金计算表模板.xlsx';
const fphdXlsx = '${rootDir}\\到龄贫困人员待遇核定情况表模板.xlsx';

void fphd(List args) async {
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

void download(List args) async {
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

      var records = await model.select(
          And([
            Eq(#idcard, idcard),
            Or.Eq(#type, ['贫困人口', '特困人员', '全额低保人员', '差额低保人员'])
          ]),
          order: Order([By(#date)]));
      if (records.isNotEmpty) {
        var record = records.first;
        data.bz = '按人社厅发〔2018〕111号文办理';
        data.fpName = record.name;
        data.fpType = record.type;
        data.fpDate = record.date;
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
        ..cell('L').setValue(data.bz)
        ..cell('M').setValue(data.fpType)
        ..cell('N').setValue(data.fpDate)
        ..cell('O').setValue(data.fpName);
    }
    workbook.toFile(saveXlsx);
  }
}

void split(List args) async {
  String date = args[0];
  var ymd = getYearMonthDay(date);
  String year = ymd[0], month = ymd[1];
  int start = int.parse(args[1]);
  int end = int.parse(args[2]);

  var saveXlsx = '$rootDir\\信息核对报告表$date.xlsx';
  var outputDir = '$rootDir\\$year年$month月待遇核定数据';

  var workbook = xlsx.Workbook.fromFile(saveXlsx);
  var sheet = workbook.sheetAt(0);

  print('生成分组映射表');
  var map = <String, Map<String, List>>{};
  for (var index = start; index <= end; index++) {
    var xzqh = sheet.rowAt(index).cell('D').value();
    Match m;
    for (var regex in reXzhq) {
      m = RegExp(regex).firstMatch(xzqh);
      if (m != null) break;
    }
    if (m == null) {
      stop('未匹配行政区划: $xzqh');
    } else {
      var xzj = m[2], csq = m[3];
      if (!map.containsKey(xzj)) {
        map[xzj] = {};
      }
      if (!map[xzj].containsKey(csq)) {
        map[xzj][csq] = [index];
      } else {
        map[xzj][csq].add(index);
      }
    }
  }

  print('生成分组目录并分别生成信息核对报告表');
  var dir = Directory(outputDir);
  if (dir.existsSync()) {
    dir.renameSync(outputDir + '.orig');
  }
  dir.createSync(recursive: true);

  for (var xzj in map.keys) {
    print('$xzj:');
    Directory(p.join(outputDir, xzj)).createSync();

    for (var csq in map[xzj].keys) {
      print('  $csq: ${map[xzj][csq]}');
      Directory(p.join(outputDir, xzj, csq)).createSync();

      var outWorkbook = xlsx.Workbook.fromFile(infoXlsx);
      var outSheet = outWorkbook.sheetAt(0);
      var startRow = 4, currentRow = 4;

      map[xzj][csq].forEach((rowIndex) {
        var index = currentRow - startRow + 1;

        var inRow = sheet.rowAt(rowIndex);

        print(
            '    $index ${inRow.cell('C').value()} ${inRow.cell('B').value()}');

        outSheet.copyRowTo(startRow, currentRow++, clearValue: true)
          ..cell('A').setValue(index)
          ..cell('B').setValue(inRow.cell('B').value())
          ..cell('C').setValue(inRow.cell('C').value())
          ..cell('D').setValue(inRow.cell('D').value())
          ..cell('E').setValue(inRow.cell('E').value())
          ..cell('F').setValue(inRow.cell('F').value())
          ..cell('G').setValue('是 [ ]')
          ..cell('H').setValue('否 [ ]')
          ..cell('I').setValue('是 [ ]')
          ..cell('J').setValue('否 [ ]')
          ..cell('L').setValue(inRow.cell('L').value());
      });

      outWorkbook.toFile(p.join(outputDir, xzj, csq, '$csq信息核对报告表.xlsx'));
    }
  }

  print('\n按分组生成养老金养老金计算表');
  Session.use((session) {
    for (var xzj in map.keys) {
      for (var csq in map[xzj].keys) {
        map[xzj][csq].forEach((index) {
          var row = sheet.rowAt(index);
          var name = row.cell('B').value();
          var idcard = row.cell('C').value();
          print('  $idcard $name');
          try {
            _getPaymentReport(
                session, name, idcard, p.join(outputDir, xzj, csq));
          } catch (e) {
            print('  $idcard $name 获得养老金计算表岀错: $e');
          }
        });
      }
    }
  });
}

_getPaymentReport(Session session, String name, String idcard, String outdir,
    [int retry = 3]) {
  session.sendService(DyfhQuery(idcard: idcard, shzt: '0'));
  var result = session.getResult<Dyfh>();
  if (result.isNotEmpty) {
    session.sendService(BankInfoQuery(idcard));
    var bankInfoResult = session.getResult<BankInfo>();

    var payInfo = result[0].paymentInfo;
    while (payInfo == null) {
      if (--retry > 1) {
        payInfo = result[0].paymentInfo;
      } else {
        throw '养老金计算信息无效';
      }
    }
    var workbook = xlsx.Workbook.fromFile(payInfoXslx);
    var sheet = workbook.sheetAt(0)
      ..cell('A5').setValue(payInfo[1])
      ..cell('B5').setValue(payInfo[2])
      ..cell('C5').setValue(payInfo[3])
      ..cell('F5').setValue(payInfo[4])
      ..cell('H5').setValue(payInfo[5])
      ..cell('K5').setValue(payInfo[6])
      ..cell('A8').setValue(payInfo[7])
      ..cell('B8').setValue(payInfo[8])
      ..cell('C8').setValue(payInfo[9])
      ..cell('E8').setValue(payInfo[10])
      ..cell('F8').setValue(payInfo[11])
      ..cell('G8').setValue(payInfo[12])
      ..cell('H8').setValue(payInfo[13])
      ..cell('I8').setValue(payInfo[14])
      ..cell('J8').setValue(payInfo[15])
      ..cell('K8').setValue(payInfo[16])
      ..cell('L8').setValue(payInfo[17])
      ..cell('A11').setValue(payInfo[18])
      ..cell('B11').setValue(payInfo[19])
      ..cell('C11').setValue(payInfo[20])
      ..cell('D11').setValue(payInfo[21])
      ..cell('E11').setValue(payInfo[22])
      ..cell('F11').setValue(payInfo[23])
      ..cell('G11').setValue(payInfo[24])
      ..cell('H11').setValue(payInfo[25])
      ..cell('I11').setValue(payInfo[26])
      ..cell('J11').setValue(payInfo[27])
      ..cell('K11').setValue(payInfo[28])
      ..cell('L11').setValue(payInfo[29])
      ..cell('H12').setValue(
          '${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');

    if (bankInfoResult.isNotEmpty) {
      var bankInfo = bankInfoResult[0];
      if (bankInfo.name != null) {
        sheet.cell('B15').setValue(bankInfo.name);
      }
      var bankName = bankInfo.bankName;
      if (bankName != null) {
        sheet.cell('F15').setValue(bankName);
      }
      if (bankInfo.cardNumber != null) {
        var card = bankInfo.cardNumber;
        var l = card.length;
        var repeat = (s, t) {
          var r = '';
          for (var i = 0; i < t; i++) {
            r += s;
          }
          return r;
        };
        if (l > 7) {
          card =
              card.substring(0, 3) + repeat('*', l - 7) + card.substring(l - 4);
        } else if (l > 4) {
          card = repeat('*', l - 4) + card.substring(l - 4);
        }
        sheet.cell('J15').setValue(card);
      } else {
        sheet.cell('B15').setValue('未绑定银行账户');
      }

      workbook.toFile(p.join(outdir, '$name[$idcard]养老金计算表.xlsx'));
    }
  } else {
    throw '未查到该人员核定数据';
  }
}
