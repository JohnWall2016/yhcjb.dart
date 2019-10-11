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
  num year = 0;
  num grjf = 0, sjbt = 0, sqbt = 0, xjbt = 0, zfdj = 0;
  Set<String> sbjg = Set();
  Set<String> hbrq = Set();

  @override
  String toString() {
    return '$year'.padLeft(4) + '$grjf'.padLeft(9) + '$sjbt'.padLeft(9) +
      '$sqbt'.padLeft(9) + '$xjbt'.padLeft(9) + '$zfdj'.padLeft(9) +
      '  ${sbjg.join('|')} ${hbrq.join('|')}';
  }
}

jfxx(Map args) {
  //print('${args['idcard']} ${args['\'export\'']}');

  String idcard = args['idcard'];
  bool export = args['\'export\''] == 'export';

  print('身份证号码: $idcard, 是否导出: $export\n');

  Session.use((s) {
    s.sendService(SncbxxConQuery(idcard));
    var infos = s.getResult<SncbxxCon>();
    if (infos.isEmpty) {
      print('未查到参保记录');
      return;
    }
    var info = infos[0];
    var name = info.name;
    var sbjg = info.sbjg;
    var czmc = info.czmc;
    var jbsj = info.jbsj;
    print('$name $idcard $czmc $sbjg $jbsj\n');

    s.sendService(SncbqkcxjfxxQuery(idcard));
    var result = s.getResult<Sncbqkcxjfxx>();
    //print(result.toJson(true));
    if (result.isEmpty || (result.length == 1 && result[0].year == null)) {
      print('未查询到缴费信息');
    } else {
      Map<int, JfxxRecord> transferedRecords = {};
      Map<int, JfxxRecord> untransferedRecords = {};
      for (var data in result.datas) {
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
            default:
              throw '未知缴费类型';
          }
          record.sbjg.add(data.agency ?? ''); // 社保机构
          record.hbrq.add(data.transferDate ?? ''); // 划拨日期
        }
      }

      printJfxxRecords(Map<int, JfxxRecord> records, String message) {
        var keys = records.keys.toList();
        keys.sort();
        var len = keys.length;
        print(message);
        print('年度'.padLeft(5) + '个人缴费'.padLeft(5) + '省级补贴'.padLeft(5) +
          '市级补贴'.padLeft(5) + '县级补贴'.padLeft(5) + '政府代缴'.padLeft(5) +
          '  社保经办机构 拨付时间');
        for (var i = 0; i < len; ++i) {
          print('${i + 1}. ${transferedRecords[keys[i]]}');
        }
      }

      printJfxxRecords(transferedRecords, '已拨付缴费历史记录:');
      printJfxxRecords(untransferedRecords, '\n未拨付补录入记录:');
    }
  });
}
