import 'package:yhcjb/yhjb.dart';
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

  program.command('upinfo')
    ..setDescription('更新xlsx中个人居保参保信息')
    ..setArguments('<xlsx> <beginRow> <endRow> <idcardCol> <infoSaveCol>', {
      'xlsx': 'xslx文件路径',
      'beginRow': '数据开始行',
      'endRow': '数据结束行(包含)',
      'idcardCol': '身份证号码所在列',
      'infoSaveCol': '居保参保信息保存列',
    })
    ..setAction((Map args) => upinfo(args));

  program.command('jfxx')
    ..setDescription('缴费信息查询')
    ..setArguments(
        '<idcard> [\'export\']', {'idcard': '身份证号码', '\'export\'': '导出信息表'})
    ..setAction((Map args) => jfxx(args));

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

      print('$i $idcard');

      session.sendService(GrinfoQuery(idcard));
      var result = session.getResult<Grinfo>();
      if (result.isNotEmpty) {
        var info = result.datas[0];

        print('${info.czmc}|${info.xzqh}|${info.dwmc}|${info.jbzt}');

        row.cell('C').setValue(info.name);
        row.cell('E').setValue(info.czmc);
        row.cell('F').setValue(info.dwmc);
        row.cell('G').setValue(info.jbzt);

        String deathTime = row.cell('D').value();

        session.sendService(PausePaymentQuery(idcard));
        var result2 = session.getResult<PausePayment>();
        if (result2.isNotEmpty) {
          var pause = result2.datas[0];

          print(
              '${pause.idcard}|${pause.name}|${pause.time}|${pause.reasonChn}|${pause.memo}');

          row.cell('H').setValue('暂停');
          var pauseTime = pause.time;
          row.cell('I').setValue(pauseTime);

          try {
            var delta =
                substractMonth(int.parse(deathTime), previousMonth(pauseTime));

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
          row.cell('M').setValue(sdeathTime);
          try {
            var delta = substractMonth(int.parse(deathTime), sdeathTime);

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

upinfo(Map args) {
  var file = args['xlsx'];
  var start = int.parse(args['beginRow']);
  var end = int.parse(args['endRow']);
  var idRow = args['idcardCol'];
  var saveRow = args['infoSaveCol'];

  var workbook = xlsx.Workbook.fromFile(file);
  var sheet = workbook.sheetAt(0);

  Session.use((session) {
    for (var i = start; i <= end; i++) {
      var row = sheet.rowAt(i);
      String idcard = row.cell(idRow).value();
      idcard = idcard.toUpperCase();

      String jbzt;
      session.sendService(SncbxxConQuery(idcard));
      var info = session.getResult<SncbxxCon>();
      if (info.datas.isNotEmpty) {
        jbzt = info.datas[0].jbzt;
        row.cell(saveRow).setValue(jbzt);
      }

      print('$idcard ${jbzt ?? ''}');
    }
  });
  workbook.toFile(appendToFileName(file, '.upd'));
}

class JfxxRecord {
  /// 缴费年度
  num year;

  /// 个人缴费
  num grjf = 0;

  /// 省级补贴
  num sjbt = 0;

  /// 市级补贴
  num sqbt = 0;

  /// 县级补贴
  num xjbt = 0;

  /// 政府代缴
  num zfdj = 0;

  /// 集体补助
  num jtbz = 0;

  /// 划拨日期
  Set<String> hbrq = Set();

  /// 社保经办机构
  Set<String> sbjg = Set();

  @override
  String toString() {
    return '$year'.padLeft(4) +
        '$grjf'.padLeft(9) +
        '$sjbt'.padLeft(9) +
        '$sqbt'.padLeft(9) +
        '$xjbt'.padLeft(9) +
        '$zfdj'.padLeft(9) +
        '$jtbz'.padLeft(9) +
        '   ${sbjg.join('|')} ${hbrq.join('|')}';
  }
}

class JfxxTotalRecord extends JfxxRecord {
  num total = 0;
}

jfxx(Map args) {
  getJfxxRecords(
      Result<Sncbqkcxjfxx> jfxx,
      Map<int, JfxxRecord> transferedRecords,
      Map<int, JfxxRecord> untransferedRecords) {
    for (var data in jfxx.datas) {
      if (data.year != null) {
        var records =
            data.isTransfered ? transferedRecords : untransferedRecords;
        JfxxRecord record = records[data.year];
        if (record == null) {
          record = JfxxRecord()..year = data.year;
          records[data.year] = record;
        }
        switch (data.item.value) {
          case '1': // 个人缴费
            record.grjf += data.amount;
            break;
          case '3': // 省级财政补贴
            record.sjbt += data.amount;
            break;
          case '4': // 市级财政补贴
            record.sqbt += data.amount;
            break;
          case '5': // 县级财政补贴
            record.xjbt += data.amount;
            break;
          case '11': // 政府代缴
            record.zfdj += data.amount;
            break;
          case '6': // 集体补助
            record.jtbz += data.amount;
            break;
          default:
            print('未知缴费类型${data.item.value}, 金额${data.amount}\n');
        }
        record.sbjg.add(data.agency ?? ''); // 社保机构
        record.hbrq.add(data.transferDate ?? ''); // 划拨日期
      }
    }
  }

  List<JfxxRecord> orderAndTotal(Map<int, JfxxRecord> records) {
    var results = records.values.toList();
    results.sort((p, n) => p.year - n.year);
    var total = JfxxTotalRecord();
    results.forEach((r) => total
      ..grjf += r.grjf
      ..sjbt += r.sjbt
      ..sqbt += r.sqbt
      ..xjbt += r.xjbt
      ..zfdj += r.zfdj
      ..jtbz += r.jtbz);
    total.total = total.grjf +
        total.sjbt +
        total.sqbt +
        total.xjbt +
        total.zfdj +
        total.jtbz;
    return results..add(total);
  }

  printInfo(SncbxxCon info) {
    var idcard = info.idcard;
    var name = info.name;
    var sbjg = info.sbjg;
    var czmc = info.czmc;
    var jbsj = info.jbsj;
    var jbzt = info.jbzt;
    var jbsf = info.jbsf;
    print('个人信息:');
    print('$name $idcard $jbzt $jbsf $czmc $sbjg $jbsj\n');
  }

  printJfxxRecords(List<JfxxRecord> records, String message) {
    print(message);
    print('序号'.padLeft(2) +
        '年度'.padLeft(3) +
        '个人缴费'.padLeft(6) +
        '省级补贴'.padLeft(5) +
        '市级补贴'.padLeft(5) +
        '县级补贴'.padLeft(5) +
        '政府代缴'.padLeft(5) +
        '集体补助'.padLeft(5) +
        '  社保经办机构 划拨时间');
    format(JfxxRecord r) {
      return (r is JfxxTotalRecord ? '合计' : '${r.year}'.padLeft(4)) +
          '${r.grjf}'.padLeft(9) +
          '${r.sjbt}'.padLeft(9) +
          '${r.sqbt}'.padLeft(9) +
          '${r.xjbt}'.padLeft(9) +
          '${r.zfdj}'.padLeft(9) +
          '${r.jtbz}'.padLeft(9) +
          (r is JfxxTotalRecord
              ? '   总计: ${r.total}'.padLeft(9)
              : '   ${r.sbjg.join('|')} ${r.hbrq.join('|')}');
    }

    var i = 1;
    for (var r in records) {
      print('${r is JfxxTotalRecord ? '' : i++}'.padLeft(3) + '  ' + format(r));
    }
  }

  //print('${args['idcard']} ${args['\'export\'']}');

  String idcard = args['idcard'];
  bool export = args['\'export\''] == 'export';

  print('身份证号码: $idcard, 是否导出: $export\n');

  SncbxxCon info;
  Result<Sncbqkcxjfxx> jfxx;
  Session.use((s) {
    s.sendService(SncbxxConQuery(idcard));
    var infos = s.getResult<SncbxxCon>();
    if (infos.isEmpty || infos[0].invalid) {
      return;
    }
    info = infos[0];
    s.sendService(SncbqkcxjfxxQuery(idcard));
    var result = s.getResult<Sncbqkcxjfxx>();
    if (result.isEmpty || (result.length == 1 && result[0].year == null)) {
      return;
    }
    jfxx = result;
  });

  if (info == null) {
    print('未查到参保记录');
    return;
  }

  const path = r'D:\征缴管理';
  const tmplXlsx = '$path\\雨湖区城乡居民基本养老保险缴费查询单模板.xlsx';
  xlsx.Workbook workbook;
  xlsx.Sheet sheet;

  printInfo(info);

  if (export) {
    workbook = xlsx.Workbook.fromFile(tmplXlsx);
    sheet = workbook.sheetAt(0);
    sheet
      ..cell('A5').setValue(info.name)
      ..cell('C5').setValue(info.idcard)
      ..cell('E5').setValue(info.sbjg)
      ..cell('G5').setValue(info.czmc)
      ..cell('K5').setValue(info.jbsj);
  }

  if (jfxx == null) {
    print('未查询到缴费信息');
    return;
  }

  Map<int, JfxxRecord> transferedRecords = {};
  Map<int, JfxxRecord> untransferedRecords = {};

  getJfxxRecords(jfxx, transferedRecords, untransferedRecords);

  var records = orderAndTotal(transferedRecords);
  var unrecords = orderAndTotal(untransferedRecords);

  printJfxxRecords(records, '已拨付缴费历史记录:');
  if (untransferedRecords.isNotEmpty) {
    printJfxxRecords(unrecords, '\n未拨付补录入记录:');
  }

  if (export) {
    var index = 9, copyIndex = 9;
    for (var r in records) {
      sheet.copyRowTo(copyIndex, index++)
        ..cell('A').setValue(r is! JfxxTotalRecord ? index - copyIndex : '')
        ..cell('B').setValue(r is JfxxTotalRecord ? '合计' : r.year)
        ..cell('C').setValue(r.grjf)
        ..cell('D').setValue(r.sjbt)
        ..cell('E').setValue(r.sqbt)
        ..cell('F').setValue(r.xjbt)
        ..cell('G').setValue(r.zfdj)
        ..cell('H').setValue(r.jtbz)
        ..cell('I').setValue(r is JfxxTotalRecord ? '总计' : r.sbjg.join('|'))
        ..cell('K').setValue(r is JfxxTotalRecord
            ? r.total.toStringAsFixed(2)
            : r.hbrq.join('|'));
    }
    workbook.toFile('$path\\${info.name}缴费查询单.xlsx');
  }
}
