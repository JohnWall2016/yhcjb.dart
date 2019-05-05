import 'package:mysql1/mysql1.dart';
export 'package:mysql1/mysql1.dart';

import './_config.dart';

Future<MySqlConnection> getDbConnection() async {
  final conn = await MySqlConnection.connect(new ConnectionSettings(
      host: conf['host'], port: conf['port'], user: conf['user'], password: conf['password'], db: conf['db']));
  return conn;
}

class Table {
  final String name;
  const Table({this.name});
}

class Field {
  final String name;
  const Field({this.name});
}

@Table(name: '2019年度扶贫办民政残联历史数据')
class FpHistoryBook {
  @Field(name: '序号')
  int no;

  @Field(name: '乡镇街')
  String xzj;

  @Field(name: '村社区')
  String csq;

  @Field(name: '地址')
  String address;

  @Field(name: '姓名')
  String name;

  @Field(name: '身份证号码')
  String idcard;

  @Field(name: '出生日期')
  String birthDay;

  @Field(name: '人员类型')
  String type;

  @Field(name: '类型细节')
  String detail;

  @Field(name: '数据月份')
  String date;
}

class Model<T> {
  Model() {
    
  }
}