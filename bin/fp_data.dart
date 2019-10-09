import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yhcjb/yhcjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart';
import 'package:commander/commander.dart';

main(List<String> args) {
  var program = Command()..setDescription('扶贫数据导库比对程序');

  program.command('pkrk')
    ..setDescription('导入贫困人口数据')
    ..setArguments('<date> <xlsx> <beginRow> <endRow>', {'date': 'yyyymm'})
    ..setAction((List args) {
      importFpHistoryData(fetchPkData(
          date: args[0],
          xlsx: args[1],
          beginRow: int.parse(args[2]),
          endRow: int.parse(args[3])));
    });

  program.command('tkry')
    ..setDescription('导入特困人员数据')
    ..setArguments('<date> <xlsx> <beginRow> <endRow>', {'date': 'yyyymm'})
    ..setAction((List args) {
      importFpHistoryData(fetchTkData(
          date: args[0],
          xlsx: args[1],
          beginRow: int.parse(args[2]),
          endRow: int.parse(args[3])));
    });

  program.command('csdb')
    ..setDescription('导入城市低保数据')
    ..setArguments('<date> <xlsx> <beginRow> <endRow>', {'date': 'yyyymm'})
    ..setAction((List args) {
      importFpHistoryData(fetchCsdbData(
          date: args[0],
          xlsx: args[1],
          beginRow: int.parse(args[2]),
          endRow: int.parse(args[3])));
    });

  program.command('ncdb')
    ..setDescription('导入农村低保数据')
    ..setArguments('<date> <xlsx> <beginRow> <endRow>', {'date': 'yyyymm'})
    ..setAction((List args) {
      importFpHistoryData(fetchNcdbData(
          date: args[0],
          xlsx: args[1],
          beginRow: int.parse(args[2]),
          endRow: int.parse(args[3])));
    });

  program.command('cjry')
    ..setDescription('导入残疾人员数据')
    ..setArguments('<date> <xlsx> <beginRow> <endRow>', {'date': 'yyyymm'})
    ..setAction((List args) {
      importFpHistoryData(fetchCjData(
          date: args[0],
          xlsx: args[1],
          beginRow: int.parse(args[2]),
          endRow: int.parse(args[3])));
    });

  program.command('hbdc')
    ..setDescription('合并到扶贫历史数据底册')
    ..setArguments('<date>', {'date': 'yyyymm'})
    ..setAction((List args) {
      var date = args[0];
      mergeFpData('2019年度扶贫历史数据底册', fetchFpData(date, false), recreate: false);
    });

  program.command('scdc')
    ..setDescription('生成当月扶贫数据底册')
    ..setArguments('<date>', {'date': 'yyyymm'})
    ..setAction((List args) {
      var date = args[0];
      mergeFpData('$date扶贫数据底册', fetchFpData(date, true), recreate: true);
    });

  program.command('rdsf')
    ..setDescription('认定居保身份')
    ..setArguments('<tabeName> <date>',
        {'tableName': '表名称，例如：2019年度扶贫历史数据底册, 201905扶贫数据底册', 'date': 'yyyymm'})
    ..setAction((List args) {
      affirmIndentity(args[0], args[1]);
    });

  program.command('drjb')
    ..setDescription('导入居保参保人员明细表')
    ..setArguments(
        '<xlsx> <beginRow> <endRow> [\'recreate\']')
    ..setAction((List args) {
      var recreate = false;
      if (args.length > 3 && args[3] == 'recreate') recreate = true;
      importJbData(args[0], int.parse(args[1]), int.parse(args[2]), recreate);
    });

  program.command('jbzt')
    ..setDescription('更新居保参保状态')
    ..setArguments('<tabeName> <date>', 
        {'tableName': '表名称，例如：2019年度扶贫历史数据底册, 201905扶贫数据底册', 'date': 'yyyymm'})
    ..setAction((List args) {
      updateJbzt(args[0], args[1]);
    });

  program.command('dcsj')
    ..setDescription('导出扶贫底册数据')
    ..setArguments('<tabeName>',
        {'tableName': '表名称，例如：2019年度扶贫历史数据底册, 201905扶贫数据底册'})
    ..setAction((List args) {
      var tableName = args[0];
      var tmplXlsx = 'D:\\精准扶贫\\雨湖区精准扶贫底册模板.xlsx';
      var saveXlsx = 'D:\\精准扶贫\\$tableName${getFormatDate()}.xlsx';
      exportFpData(tableName, tmplXlsx, saveXlsx);
    });

  program.command('sfbg')
    ..setDescription('导出居保参保身份变更信息表')
    ..setArguments('<dir>')
    ..setAction((List args) {
      exportChanged(args[0]);
    });

  program.parse(args);
}

Iterable<FpRawData> fetchPkData(
    {String date, String xlsx, int beginRow, int endRow}) sync* {
  var workbook = Workbook.fromFile(xlsx);
  var sheet = workbook.sheetAt(0);

  for (var index = beginRow; index <= endRow; index++) {
    var row = sheet.rowAt(index);
    if (row != null) {
      String name = row.cell('H').value();
      String idcard = row.cell('I').value();
      idcard = idcard.trim().substring(0, 18).toUpperCase();
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

Iterable<FpRawData> fetchTkData(
    {String date, String xlsx, int beginRow, int endRow}) sync* {
  var workbook = Workbook.fromFile(xlsx);
  var sheet = workbook.sheetAt(0);

  for (var index = beginRow; index <= endRow; index++) {
    var row = sheet.rowAt(index);
    if (row != null) {
      String name = row.cell('G').value();
      String idcard = row.cell('H').value();
      idcard = idcard.trim().substring(0, 18).toUpperCase();
      String birthDay = idcard.substring(6, 14);
      String xzj = row.cell('C').value();
      String csq = row.cell('D').value();

      yield FpRawData()
        ..name = name
        ..idcard = idcard
        ..birthDay = birthDay
        ..xzj = xzj
        ..csq = csq
        ..type = '特困人员'
        ..detail = '是'
        ..date = date;
    }
  }
}

Iterable<FpRawData> fetchCsdbData(
    {String date, String xlsx, int beginRow, int endRow}) sync* {
  var workbook = Workbook.fromFile(xlsx);
  var sheet = workbook.sheetAt(0);

  var colNameIdcards = [
    ['G', 'H'],
    ['I', 'J'],
    ['K', 'L'],
    ['M', 'N'],
    ['O', 'P']
  ];
  for (var index = beginRow; index <= endRow; index++) {
    var row = sheet.rowAt(index);
    if (row != null) {
      String xzj = row.cell('A').value();
      String csq = row.cell('B').value();
      String address = row.cell('D').value();

      String type = row.cell('E').value();
      for (var range in colNameIdcards) {
        String name = row.cell(range[0]).value();
        String idcard = row.cell(range[1]).value();

        if (name != null && idcard != null) {
          idcard = idcard.trim().toUpperCase();
          if (idcard.length == 18) {
            var birthDay = idcard.substring(6, 14);
            var fpdata = FpRawData()
              ..idcard = idcard
              ..name = name
              ..birthDay = birthDay
              ..xzj = xzj
              ..csq = csq
              ..address = address
              ..detail = '城市'
              ..date = date;
            if (type == '全额救助' || type == '全额') {
              fpdata.type = '全额低保人员';
            } else {
              fpdata.type = '差额低保人员';
            }
            yield fpdata;
          }
        }
      }
    }
  }
}

Iterable<FpRawData> fetchNcdbData(
    {String date, String xlsx, int beginRow, int endRow}) sync* {
  var workbook = Workbook.fromFile(xlsx);
  var sheet = workbook.sheetAt(0);

  var colNameIdcards = [
    ['H', 'J'],
    ['K', 'L'],
    ['M', 'N'],
    ['O', 'P'],
    ['Q', 'R'],
    ['S', 'T'],
    ['U', 'V'],
  ];
  for (var index = beginRow; index <= endRow; index++) {
    var row = sheet.rowAt(index);
    if (row != null) {
      String xzj = row.cell('A').value();
      String csq = row.cell('B').value();
      String address = row.cell('D').value();

      String type = row.cell('F').value();
      for (var range in colNameIdcards) {
        String name = row.cell(range[0]).value();
        String idcard = row.cell(range[1]).value();

        if (name != null && idcard != null) {
          idcard = idcard.trim().toUpperCase();
          if (idcard.length == 18) {
            var birthDay = idcard.substring(6, 14);
            var fpdata = FpRawData()
              ..idcard = idcard
              ..name = name
              ..birthDay = birthDay
              ..xzj = xzj
              ..csq = csq
              ..address = address
              ..detail = '农村'
              ..date = date;
            if (type == '全额') {
              fpdata.type = '全额低保人员';
              yield fpdata;
            } else if (type == '差额') {
              fpdata.type = '差额低保人员';
              yield fpdata;
            }
          }
        }
      }
    }
  }
}

Iterable<FpRawData> fetchCjData(
    {String date, String xlsx, int beginRow, int endRow}) sync* {
  var workbook = Workbook.fromFile(xlsx);
  var sheet = workbook.sheetAt(0);

  for (var index = beginRow; index <= endRow; index++) {
    var row = sheet.rowAt(index);
    if (row != null) {
      String name = row.cell('A').value();
      String idcard = row.cell('B').value();
      idcard = idcard.trim().substring(0, 18).toUpperCase();
      String birthDay = idcard.substring(6, 14);
      String xzj = row.cell('H').value();
      String csq = row.cell('I').value();
      String address = row.cell('G').value();
      String level = row.cell('L').value();

      var fpdata = FpRawData()
        ..name = name
        ..idcard = idcard
        ..birthDay = birthDay
        ..xzj = xzj
        ..csq = csq
        ..address = address
        ..date = date;

      switch (level) {
        case '一级':
        case '二级':
          fpdata
            ..type = '一二级残疾人员'
            ..detail = level;
          yield fpdata;
          break;
        case '三级':
        case '四级':
          fpdata
            ..type = '三四级残疾人员'
            ..detail = level;
          yield fpdata;
          break;
      }
    }
  }
}

importFpHistoryData(Iterable<FpRawData> records) async {
  var db = await getFpDatabase();
  var model = db.getModel<FpRawData>('2019年度扶贫办民政残联历史数据');
  var index = 1;
  for (var record in records) {
    print('${index++} ${record.idcard} ${record.name} ${record.type}');
    if (record.idcard != null) {
      var where = And([
        Eq(#idcard, record.idcard),
        Eq(#type, record.type),
        Eq(#date, record.date)
      ]);
      var count = await model.count(where);
      if (count > 0) {
        await model.update(record, condition: where);
      } else {
        await model.insert(record);
      }
    }
  }
  await db.close();
}

const rylx = {
  'pkry': ['贫困人口', '特困人员', '全额低保人员', '差额低保人员'],
  'cjry': ['一二级残疾人员', '三四级残疾人员']
};

Stream<FpData> fetchFpData(String date, [bool onlyPkry = false]) async* {
  var db = await getFpDatabase();
  var model = db.getModel<FpRawData>('2019年度扶贫办民政残联历史数据');

  var types = onlyPkry ? rylx['pkry'] : rylx.values.expand((list) => list);

  for (var type in types) {
    print('开始获取并转换: $type');
    var records = await model.select(And([Eq(#type, type), Eq(#date, date)]));
    for (var record in records) {
      yield record.toFpData();
    }
    print('结束获取并转换: $type');
  }

  await db.close();
}

mergeFpData(String tableName, Stream<FpData> data,
    {bool recreate = false}) async {
  var db = await getFpDatabase();
  var model = db.getModel<FpData>(tableName);

  if (recreate) {
    print('重新创建 $tableName');
    await model.createTable(recreate: recreate);
  }

  print('开始合并扶贫数据至: $tableName');
  var index = 1;
  await for (var d in data) {
    print('${index++} ${d.idcard} ${d.name}');
    if (d.idcard != null) {
      var record = await model.selectOne(Eq(#idcard, d.idcard));
      if (record == null) {
        await model.insert(d);
      } else {
        if (Model.unionTo(d, record)) await model.update(record);
      }
    }
  }
  print('结束合并扶贫数据至: $tableName');

  await db.close();
}

affirmIndentity(String tableName, String date, {SqlStmt condition}) async {
  var db = await getFpDatabase();
  var model = db.getModel<FpData>(tableName);

  print('开始认定参保人员身份: $tableName');

  var data = await model.select(condition);
  var i = 1;
  for (var d in data) {
    String jbrdsf;
    if (d.pkrk != null)
      jbrdsf = '贫困人口一级';
    else if (d.tkry != null)
      jbrdsf = '特困一级';
    else if (d.qedb != null)
      jbrdsf = '低保对象一级';
    else if (d.yejc != null)
      jbrdsf = '残一级';
    else if (d.cedb != null)
      jbrdsf = '低保对象二级';
    else if (d.ssjc != null) jbrdsf = '残二级';

    if (jbrdsf != null && d.jbrdsf != jbrdsf) {
      if (d.jbrdsf != null) {
        // hoist level
        print('${i++} ${d.idcard} ${d.name} $jbrdsf <= ${d.jbrdsf}');
        d.jbrdsf = jbrdsf;
        d.jbrdsfLastDate = date;
        await model.update(d);
      } else {
        // newly affirm
        print('${i++} ${d.idcard} ${d.name} $jbrdsf');
        d.jbrdsf = jbrdsf;
        d.jbrdsfFirstDate = date;
        await model.update(d);
      }
    }
  }

  print('结束认定参保人员身份: $tableName');

  await db.close();
}

importJbData(String xlsx, int startRow, int endRow, bool recreate) async {
  var db = await getFpDatabase();
  var model = db.getModel<Jbrymx>('居保参保人员明细表20190221');

  await model.createTable(recreate: recreate);

  print('开始导入居保参保人员明细表');

  await model.loadXlsx(
      xlsx: xlsx,
      startRow: startRow,
      endRow: endRow,
      fields: ['A', 'B', 'C', 'D', 'E', 'F', 'H', 'J', 'K', 'N']);

  print('结束导入居保参保人员明细表');

  await db.close();
}

const jbztMap = [
  [1, 3, '正常待遇'],
  [2, 3, '暂停待遇'],
  [4, 3, '终止参保'],
  [1, 1, '正常缴费'],
  [2, 2, '暂停缴费']
];

updateJbzt(String tableName, String date) async {
  var db = await getFpDatabase();
  var fpBook = db.getModel<FpData>(tableName);
  var jbTable = db.getModel<Jbrymx>('居保参保人员明细表20190221');

  print('开始更新居保状态: $tableName');

  for (var list in jbztMap) {
    var cbzt = list[0], jfzt = list[1], jbzt = list[2];
    var sql = '''
update ${fpBook.name}, ${jbTable.name}
   set ${fpBook[#jbcbqk]}='$jbzt',
       ${fpBook[#jbcbqkDate]}='$date'
 where ${fpBook[#idcard]}=${jbTable[#idcard]}
   and ${jbTable[#cbzt]}='$cbzt'
   and ${jbTable[#jfzt]}='$jfzt'
''';
    print(sql);
    await db.execSql(sql);
  }

  print('结束更新居保状态: $tableName');

  await db.close();
}

const exportMap = {
  'B': 'no',
  'C': 'xzj',
  'D': 'csq',
  'E': 'address',
  'F': 'name',
  'G': 'idcard',
  'H': 'birthDay',
  'I': 'pkrk',
  'J': 'pkrkDate',
  'K': 'tkry',
  'L': 'tkryDate',
  'M': 'qedb',
  'N': 'qedbDate',
  'O': 'cedb',
  'P': 'cedbDate',
  'Q': 'yejc',
  'R': 'yejcDate',
  'S': 'ssjc',
  'T': 'ssjcDate',
  'U': 'sypkry',
  'V': 'jbrdsf',
  'W': 'jbrdsfFirstDate',
  'X': 'jbrdsfLastDate',
  'Y': 'jbcbqk',
  'Z': 'jbcbqkDate'
};

exportFpData(String tableName, String tmplXlsx, String saveXlsx,
    {SqlStmt condition}) async {
  var db = await getFpDatabase();
  var fpBook = db.getModel<FpData>(tableName);

  print('开始导出扶贫底册: ${tableName}=>${saveXlsx}');

  var workbook = Workbook.fromFile(tmplXlsx);
  var sheet = workbook.sheetAt(0);
  var startRow = 3, currentRow = 3;

  var data = await fpBook.select(condition);

  for (var d in data) {
    var index = currentRow - startRow + 1;

    print('$index ${d.idcard} ${d.name}');

    var row = sheet.copyRowTo(startRow, currentRow++, clearValue: true);
    row.cell('A').setValue(index);

    exportMap.forEach((col, field) {
      var value = Model.value(d, field);
      if (value != null) row.cell(col).setValue(value);
    });
  }

  await workbook.toFile(saveXlsx);

  print('结束导出扶贫底册: ${tableName}=>${saveXlsx}');

  await db.close();
}

const jbsfMap = [
  ['贫困人口一级', '051'],
  ['特困一级', '031'],
  ['低保对象一级', '061'],
  ['低保对象二级', '062'],
  ['残一级', '021'],
  ['残二级', '022']
];

exportChanged(String path) async {
  var tmplXlsx = 'D:\\精准扶贫\\批量信息变更模板.xlsx';
  var rowsPerXlsx = 500;

  var dir = Directory(path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  } else {
    print('目录已存在: $path');
    return;
  }

  var db = await getFpDatabase();
  var fpBook = db.getModel<FpData>('2019年度扶贫历史数据底册');
  var jbTable = db.getModel<Jbrymx>('居保参保人员明细表20190221');

  print('从 ${fpBook.name} 和 ${jbTable.name} 导出信息变更表');

  for (var list in jbsfMap) {
    var type = list[0], code = list[1];

    var sql = '''
select ${jbTable[#name]} as name, ${jbTable[#idcard]} as idcard
  from ${jbTable.name}, ${fpBook.name}
 where ${jbTable[#idcard]}=${fpBook[#idcard]}
   and ${fpBook[#jbrdsf]}='$type'
   and ${jbTable[#cbsf]}<>'$code'
   and ${jbTable[#cbzt]}='1'
   and ${jbTable[#jfzt]}='1'
''';
    print(sql + '\n');

    var data = await db.query(sql);

    if (data.isNotEmpty) {
      print('开始导出 $type 批量信息变更表');

      int i = 0, files = 0;
      Workbook workbook;
      Sheet sheet;
      int startRow = 2, currentRow = 2;
      for (var d in data) {
        if (i++ % rowsPerXlsx == 0) {
          if (workbook != null) {
            workbook.toFile(p.join(path, '${type}批量信息变更表${++files}.xlsx'));
            workbook = null;
          }
          if (workbook == null) {
            workbook = Workbook.fromFile(tmplXlsx);
            sheet = workbook.sheetAt(0);
            currentRow = 2;
          }
        }
        var row = sheet.copyRowTo(startRow, currentRow++);
        row.cell('A').setValue(d[1]);
        row.cell('C').setValue(d[0]);
        row.cell('H').setValue(code);
      }
      if (workbook != null) {
        workbook.toFile(p.join(path, '${type}批量信息变更表${++files}.xlsx'));
      }

      print('结束导出 $type 批量信息变更表: $i 条');
    }
  }

  await db.close();
}
