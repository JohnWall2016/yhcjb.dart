import './_config.dart';
import '../db/db.dart';

Future<MySqlConnection> getDbConnection() async {
  final conn = await MySqlConnection.connect(new ConnectionSettings(
      host: dbconf['host'],
      port: dbconf['port'],
      user: dbconf['user'],
      password: dbconf['password'],
      db: dbconf['db']));
  return conn;
}

Future<Database> getFpDatabase() async {
  return await Database.connect(
      host: dbconf['host'],
      port: dbconf['port'],
      user: dbconf['user'],
      password: dbconf['password'],
      db: dbconf['db']);
}

/// 扶贫历史数据
class FpRawData {
  @Field(name: '序号', primaryKey: true, autoIncrement: true)
  int no;

  @Field(name: '乡镇街')
  String xzj;

  @Field(name: '村社区')
  String csq;

  @Field(name: '地址')
  String address;

  @Field(name: '姓名')
  String name;

  @Field(name: '身份证号码', primaryKey: true)
  String idcard;

  @Field(name: '出生日期')
  String birthDay;

  @Field(name: '人员类型')
  String type;

  @Field(name: '类型细节')
  String detail;

  @Field(name: '数据月份')
  String date;

  FpData toFpData() {
    var fpdata = FpData()
      ..xzj = xzj
      ..csq = csq
      ..address = address
      ..name = name
      ..idcard = idcard
      ..birthDay = birthDay;
    switch (type) {
      case '贫困人口':
        fpdata
          ..sypkry = '贫困人口'
          ..pkrk = detail
          ..pkrkDate = date;
        break;
      case '特困人员':
        fpdata
          ..sypkry = '特困人员'
          ..tkry = detail
          ..tkryDate = date;
        break;
      case '全额低保人员':
        fpdata
          ..sypkry = '低保对象'
          ..qedb = detail
          ..qedbDate = date;
        break;
      case '差额低保人员':
        fpdata
          ..sypkry = '低保对象'
          ..cedb = detail
          ..cedbDate = date;
        break;
      case '一二级残疾人员':
        fpdata
          ..yejc = detail
          ..yejcDate = date;
        break;
      case '三四级残疾人员':
        fpdata
          ..ssjc = detail
          ..ssjcDate = date;
        break;
    }
    return fpdata;
  }

  @override
  String toString() {
    return '$idcard $name $xzj $csq $birthDay $type $detail $date';
  }
}

/// 扶贫数据
class FpData {
  @Field(name: '序号', primaryKey: true, autoIncrement: true)
  int no;

  @Field(name: '乡镇街')
  String xzj;

  @Field(name: '村社区')
  String csq;

  @Field(name: '地址')
  String address;

  @Field(name: '姓名')
  String name;

  @Field(name: '身份证号码', primaryKey: true)
  String idcard;

  @Field(name: '出生日期')
  String birthDay;

  @Field(name: '贫困人口')
  String pkrk;

  @Field(name: '贫困人口日期')
  String pkrkDate; // 记录录入数据的月份 201902

  @Field(name: '特困人员')
  String tkry;

  @Field(name: '特困人员日期')
  String tkryDate; // 记录录入数据的月份 201902

  @Field(name: '全额低保人员')
  String qedb;

  @Field(name: '全额低保人员日期')
  String qedbDate; // 记录录入数据的月份 201902

  @Field(name: '差额低保人员')
  String cedb;

  @Field(name: '差额低保人员日期')
  String cedbDate; // 记录录入数据的月份 201902

  @Field(name: '一二级残疾人员')
  String yejc;

  @Field(name: '一二级残疾人员日期')
  String yejcDate; // 记录录入数据的月份 201902

  @Field(name: '三四级残疾人员')
  String ssjc;

  @Field(name: '三四级残疾人员日期')
  String ssjcDate; // 记录录入数据的月份 201902

  @Field(name: '属于贫困人员')
  String sypkry;

  @Field(name: '居保认定身份')
  String jbrdsf;

  @Field(name: '居保认定身份最初日期')
  String jbrdsfFirstDate;

  @Field(name: '居保认定身份最后日期')
  String jbrdsfLastDate;

  @Field(name: '居保参保情况')
  String jbcbqk;

  @Field(name: '居保参保情况日期')
  String jbcbqkDate;
}

/// 居保参保人员明细表
class Jbrymx {
  @Field(name: '行政区划')
  String xzqh;

  @Field(name: '户籍性质')
  String hjxz;

  @Field(name: '姓名')
  String name;

  @Field(name: '身份证号码', primaryKey: true)
  String idcard;

  @Field(name: '性别')
  String sex;

  @Field(name: '出生日期')
  String birthDay;

  @Field(name: '参保身份')
  String cbsf;

  @Field(name: '参保状态')
  String cbzt;

  @Field(name: '缴费状态')
  String jfzt;

  @Field(name: '参保时间')
  String cbsj;
}