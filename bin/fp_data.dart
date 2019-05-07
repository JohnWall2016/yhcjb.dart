import 'package:yhcjb/yhcjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart';

main(List<String> args) {
  CommandRunner('fp_data', '扶贫数据导库比对程序')
    ..addCommand(Pkrk())
    ..addCommand(Tkry())
    ..addCommand(Csdb())
    ..addCommand(Ncdb())
    ..addCommand(Cjry())
    ..addCommand(Scdc())
    ..addCommand(Rdsf())
    ..run(args);
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
      idcard = idcard.trim().substring(0, 18);
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
      String name = row.cell('E').value();
      String idcard = row.cell('G').value();
      idcard = idcard.trim().substring(0, 18);
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
            if (type == '全额救助') {
              fpdata.type = '全额低保人员';
              yield fpdata;
            } else if (type == '差额救助') {
              fpdata.type = '差额低保人员';
              yield fpdata;
            }
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
      idcard = idcard.trim().substring(0, 18);
      String birthDay = idcard.substring(6, 14);
      String xzj = row.cell('H').value();
      String csq = row.cell('I').value();
      String address = row.cell('G').value();
      String level = row.cell('E').value();

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
      if (count > 0)
        await model.update(record, condition: where);
      else
        await model.insert(record);
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
    print('重新创建$tableName');
    await model.createTable(ifNotExists: false);
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
    if (d.pkrk != null) jbrdsf = '贫困人口一级';
    else if (d.tkry != null) jbrdsf = '特困一级';
    else if (d.qedb != null) jbrdsf = '低保对象一级';
    else if (d.yejc != null) jbrdsf = '残一级';
    else if (d.cedb != null) jbrdsf = '低保对象二级';
    else if (d.ssjc != null) jbrdsf = '残二级';

    if (jbrdsf != null && d.jbrdsf != jbrdsf) {
      if (d.jbrdsf != null) { // hoist level
        print('${i++} ${d.idcard} ${d.name} $jbrdsf <= ${d.jbrdsf}');
        d.jbrdsf = jbrdsf;
        d.jbrdsfLastDate = date;
        await model.update(d);
      } else { // newly affirm
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

class Pkrk extends ArgumentsCommand {
  Pkrk()
      : super('pkrk',
            description: '导入贫困人口数据',
            arguments: '<date:yyyymm> <xlsx> <beginRow> <endRow>');
  @override
  void execute(List<String> args) async {
    importFpHistoryData(fetchPkData(
        date: args[0],
        xlsx: args[1],
        beginRow: int.parse(args[2]),
        endRow: int.parse(args[3])));
  }
}

class Tkry extends ArgumentsCommand {
  Tkry()
      : super('tkry',
            description: '导入特困人员数据',
            arguments: '<date:yyyymm> <xlsx> <beginRow> <endRow>');
  @override
  void execute(List<String> args) async {
    importFpHistoryData(fetchTkData(
        date: args[0],
        xlsx: args[1],
        beginRow: int.parse(args[2]),
        endRow: int.parse(args[3])));
  }
}

class Csdb extends ArgumentsCommand {
  Csdb()
      : super('csdb',
            description: '导入城市低保数据',
            arguments: '<date:yyyymm> <xlsx> <beginRow> <endRow>');
  @override
  void execute(List<String> args) async {
    importFpHistoryData(fetchCsdbData(
        date: args[0],
        xlsx: args[1],
        beginRow: int.parse(args[2]),
        endRow: int.parse(args[3])));
  }
}

class Ncdb extends ArgumentsCommand {
  Ncdb()
      : super('ncdb',
            description: '导入农村低保数据',
            arguments: '<date:yyyymm> <xlsx> <beginRow> <endRow>');
  @override
  void execute(List<String> args) async {
    importFpHistoryData(fetchNcdbData(
        date: args[0],
        xlsx: args[1],
        beginRow: int.parse(args[2]),
        endRow: int.parse(args[3])));
  }
}

class Cjry extends ArgumentsCommand {
  Cjry()
      : super('cjry',
            description: '导入残疾人员数据',
            arguments: '<date:yyyymm> <xlsx> <beginRow> <endRow>');
  @override
  void execute(List<String> args) async {
    importFpHistoryData(fetchCjData(
        date: args[0],
        xlsx: args[1],
        beginRow: int.parse(args[2]),
        endRow: int.parse(args[3])));
  }
}

class Scdc extends ArgumentsCommand {
  Scdc() : super('scdc', description: '生成当月扶贫数据底册', arguments: '<date:yyyymm>');
  @override
  void execute(List<String> args) async {
    var date = args[0];
    mergeFpData('$date扶贫数据底册', fetchFpData(date, true), recreate: true);
  }
}

class Rdsf extends ArgumentsCommand {
  Rdsf() : super('rdsf', description: '认定居保身份', arguments: '<tabeName> <date:yyyymm>');
  @override
  void execute(List<String> args) async {
    affirmIndentity(args[0], args[1]);
  }
}