import 'package:yhcjb/yhcjb.dart';

main() async {
  /*var model = Model<FpHistoryData>(null);

  print(model.getName(#name));
  print(model.getSymbol('姓名'));
  print(model.getFieldName(#name));

  print(model.selectSql(Eq(#name, '刘德华')));
  print(model.selectSql(Is(#name, null)));
  print(model.selectSql(And([
    Eq(#idcard, '12345'),
    Or.Eq(#type, ['贫困人口', '特困人员', '全额低保人员', '差额低保人员']),
    Eq(#date, 2014)
  ])));

  print(model.insertSql(FpHistoryData()
    ..name = '刘德华'
    ..idcard = '123456'));

  print(model.updateSql(FpHistoryData()
    ..name = '刘德华'
    ..idcard = '123456'));*/

  var db = await getFpDatabase();
  var model = db.getModel<FpHistoryData>('2019年度扶贫办民政残联历史数据');
  var records = await model.select(/*Eq(#type, '特困人员')*/null);
  var index = 1;
  for (var data in records) {
    print('${index++} ${data.idcard} ${data.name}');
  }
  print(await model.count(/*Eq(#type, '特困人员')*/null));
  await db.close();
}