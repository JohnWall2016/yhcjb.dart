import 'dart:convert';

import './sync_socket.dart';
import '../json/json.dart';
export '../json/json.dart';
import './_config.dart';

typedef void Action(Session session);

class Session extends SyncSocket {
  String _userId;
  String _password;
  String _sessionId, _cxCookie;

  Session(String host, int port, String userId, String password)
      : _userId = userId,
        _password = password,
        super(host, port);

  HttpRequest _createRequest() {
    var request = HttpRequest('/hncjb/reports/crud', method: 'POST')
      ..addHeader('Host', url)
      ..addHeader('Connection', 'keep-alive')
      ..addHeader('Accept', 'application/json, text/javascript, */*; q=0.01')
      ..addHeader('Origin', 'http://${url}')
      ..addHeader('X-Requested-With', 'XMLHttpRequest')
      ..addHeader('User-Agent',
          'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36')
      ..addHeader('Content-Type', 'multipart/form-data;charset=UTF-8')
      ..addHeader('Referer', 'http://${url}/hncjb/pages/html/index.html')
      ..addHeader('Accept-Encoding', 'gzip, deflate')
      ..addHeader('Accept-Language', 'zh-CN,zh;q=0.8');
    if (_sessionId != null) {
      request.addHeader(
          'Cookie', 'jsessionid_ylzcbp=$_sessionId; cxcookie=$_cxCookie');
    }
    return request;
  }

  HttpRequest _buildRequest(String content) {
    var request = _createRequest();
    request.addBody(content);
    return request;
  }

  void request(String content) {
    var req = _buildRequest(content);
    write(req.toBytes());
  }

  void sendService(Parameters params) {
    var serv = Service(params: params, userId: _userId, password: _password);
    request(serv.toJson());
  }

  void sendServiceWithId(String id) {
    var serv = Service.withId(id: id, userId: _userId, password: _password);
    request(serv.toJson());
  }

  Result<T> getResult<T extends Data>() {
    var result = readHttpBody();
    return Jsonable.fromJson<Result<T>>(result);
  }

  String login() {
    sendServiceWithId('loadCurrentUser');
    var header = readHttpHeader();
    var cookies = header['set-cookie'];
    cookies?.forEach((cookie) {
      var match = RegExp("jsessionid_ylzcbp=(.+?);").firstMatch(cookie);
      if (match != null) {
        _sessionId = match.group(1);
        return;
      }
      match = RegExp("cxcookie=(.+?);").firstMatch(cookie);
      if (match != null) {
        _cxCookie = match.group(1);
        return;
      }
    });
    readHttpBody(header);

    sendService(Syslogin(_userId, _password));
    return readHttpBody();
  }

  String logout() {
    sendServiceWithId('syslogout');
    return readHttpBody();
  }

  static void use(Action action, {String user = '002'}) {
    var session = Session(conf['host'], conf['port'], conf['users'][user]['id'],
        conf['users'][user]['pwd']);
    try {
      session.login();
      action(session);
      session.logout();
    } finally {
      session.close();
    }
  }
}

class Service extends Jsonable {
  String serviceid;
  String target = '';
  String sessionid;
  String loginname;
  String password;
  Parameters params;
  List<Parameters> datas = [];

  Service({Parameters params, String userId, String password}) {
    serviceid = params.serviceId;
    loginname = userId;
    this.password = password;
    this.params = params;
    datas.add(this.params);
  }

  Service.withId({String id, String userId, String password}) {
    serviceid = id;
    loginname = userId;
    this.password = password;
    this.params = Parameters(id);
    datas.add(this.params);
  }
}

class Parameters extends Jsonable {
  @Json(ignored: true)
  final String serviceId;

  Parameters(this.serviceId);
}

class PageParameters extends Parameters {
  final int page;

  @Json(name: 'pagesize')
  final int pageSize;

  final List filtering;
  final List sorting;
  final List totals;

  PageParameters(String id,
      {this.page = 1,
      this.pageSize = 15,
      this.filtering = const [],
      this.sorting = const [],
      this.totals = const []})
      : super(id);

  void addFiltering(Map filtering) => this.sorting.add(filtering);

  void addSorting(Map sorting) => this.sorting.add(sorting);

  void addTotals(Map totals) => this.totals.add(totals);
}

class Data extends Jsonable {}

class Result<T extends Data> extends Jsonable {
  @Json(name: 'rowcount')
  int rowCount;

  int page;

  @Json(name: 'pagesize')
  int pageSize;

  @Json(name: 'serviceid')
  String serviceId;

  String type, vcode, message;

  @Json(name: 'messagedetail')
  String messageDetail;

  @Json(name: 'datas')
  List<T> _datas;

  List<T> get datas => _datas != null ? _datas : [];

  T operator [](int index) => datas[index];
  int get length => datas.length;

  bool get isEmpty => datas.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

class Syslogin extends Parameters {
  final String username, passwd;
  Syslogin(this.username, this.passwd) : super('syslogin');
}

class GrinfoQuery extends PageParameters {
  /// 行政区划编码
  @Json(name: "aaf013")
  String xzqh = "";

  /// 村级编码
  @Json(name: "aaz070")
  String cjbm = "";

  String aaf101 = "", aac009 = "";

  /// 参保状态: "1"-正常参保 "2"-暂停参保 "4"-终止参保 "0"-未参保
  @Json(name: "aac008")
  String cbzt = "";

  ///缴费状态: "1"-参保缴费 "2"-暂停缴费 "3"-终止缴费
  @Json(name: "aac031")
  String jfzt = "";

  String aac006str = "", aac006end = "";
  String aac066 = "", aae030str = "";
  String aae030end = "", aae476 = "";

  @Json(name: "aac003")
  String name = "";

  /// 身份证号码
  @Json(name: "aac002")
  String idcard = "";

  String aae478 = "";

  GrinfoQuery(String idcard) : super("zhcxgrinfoQuery") {
    this.idcard = idcard;
  }
}

/// 省内参保信息查询
class SncbxxConQuery extends Parameters {
  /// 身份证号码
  @Json(name: "aac002")
  String idcard = "";

  SncbxxConQuery(String idcard) : super("executeSncbxxConQ") {
    this.idcard = idcard;
  }
}

abstract class BaseInfo {
  /// 个人编号
  @Json(name: 'aac001')
  int grbh;

  /// 身份证号码
  @Json(name: 'aac002')
  String idcard;

  @Json(name: 'aac003')
  String name;
}

abstract class PersionInfo {
  /// 个人编号
  @Json(name: 'aac001')
  int grbh;

  /// 身份证号码
  @Json(name: 'aac002')
  String idcard;

  @Json(name: 'aac003')
  String name;

  @Json(name: 'aac004')
  String sex;

  /// 民族
  @Json(name: 'aac005')
  String nation;

  @Json(name: 'aac006')
  int birthday;

  /// 参保状态: "1"-正常参保 "2"-暂停参保 "4"-终止参保 "0"-未参保
  @Json(name: 'aac008')
  String cbzt;

  /// 户籍
  @Json(name: 'aac009')
  String domicile;

  /// 户口所在地
  @Json(name: 'aac010')
  String hkszd;

  /// 缴费状态: "1"-参保缴费 "2"-暂停缴费 "3"-终止缴费
  @Json(name: 'aac031')
  String jfzt;

  /// 参保时间
  @Json(name: 'aac049')
  int cbrq;

  /// 参保身份
  @Json(name: 'aac066')
  String cbsf;

  /// 居保状态
  String get jbzt => _jbzt(cbzt, jfzt);

  bool get valid => idcard != null;

  bool get invalid => !valid;
}

abstract class ExtraInfo {
  @Json(name: "aae005")
  String phone;

  @Json(name: "aae006")
  String address;

  @Json(name: "aae010")
  String bankcard;
}

abstract class Region {
  /// 村社区名称
  @Json(name: "aaf103")
  String region;
}

abstract class Address {
  /// 行政区划编码
  @Json(name: "aaf101")
  String xzqh;

  /// 村组名称
  @Json(name: "aaf102")
  String czmc;

  /// 村社区名称
  @Json(name: "aaf103")
  String csmc;

  /// 单位名称
  String get dwmc {
    return _xzqhMap[xzqh.substring(0, 8)] ?? '';
  }
}

/// 业务经办审核
abstract class Ywjbsh {
  /// 审核状态
  @Json(name: 'aae016')
  String shzt;

  /// 经办人
  @Json(name: 'aae011')
  String jbr;

  /// 经办时间
  @Json(name: 'aae036')
  String jbsj;

  /// 审核人
  @Json(name: 'aae014')
  String shr;

  /// 审核时间
  @Json(name: 'aae015')
  String shsj;
}

/// 个人综合信息
class Grinfo extends Data with PersionInfo, ExtraInfo, Address {}

/// 省内参保信息
class SncbxxCon extends Data with PersionInfo, ExtraInfo, Address {
  /// 社保机构
  @Json(name: 'aaa129')
  String sbjg;

  /// 经办时间
  @Json(name: 'aae036')
  String jbsj;
}

class CbshQuery extends PageParameters {
  String aaf013 = "",
      aaf030 = "",
      aae011 = "",
      aae036 = "",
      aae036s = "",
      aae014 = "",
      aae015s = "",
      aac009 = "",
      aac002 = "",
      aac003 = "",
      sfccb = "";

  @Json(name: 'aae015')
  String qsshsj = ""; // "2019-04-29";

  @Json(name: 'aae015s')
  String jzshsj = "";

  @Json(name: 'aae016')
  String shzt = ""; // "1";

  CbshQuery({this.qsshsj = '', this.jzshsj = '', this.shzt = ''})
      : super('cbshQuery', pageSize: 500);
}

class Cbsh extends Data with PersionInfo, Address, Ywjbsh {}

class DyryQuery extends PageParameters {
  String aaf013 = '', aaf030 = '';

  /// 预算到龄日期
  /// 2019-04-30
  String dlny = '';

  /// 预算后待遇起始时间: '1'-到龄次月
  String yssj = '';

  String aac009 = '';

  /// 是否欠费
  String qfbz = '';

  String aac002 = '';

  /// 参保状态: '1'-正常参保
  @Json(name: 'aac008')
  String cbzt = '';

  /// 是否和社保比对: '1'-是 '2'-否
  @Json(name: 'sb_type')
  String sbbd = '';

  DyryQuery({this.dlny, this.yssj = '1', this.cbzt = '1', this.sbbd = '1'})
      : super('dyryQuery', page: 1, pageSize: 500, sorting: [
          {"dataKey": "xzqh", "sortDirection": "ascending"}
        ]);
}

class Dyry extends Data {
  @Json(name: 'xm')
  String name;

  @Json(name: 'sfz')
  String idcard;

  @Json(name: 'csrq')
  int birthDay;

  @Json(name: 'rycbzt')
  String cbzt;

  @Json(name: 'aac031')
  String jfzt;

  /// 企保参保
  @Json(name: 'qysb_type')
  String qbzt;

  /// 共缴年限
  String gjnx;

  /// 待遇领取年月
  String lqny;

  /// 备注
  String bz;

  /// 行政区划
  String xzqh;

  /// 性别
  String xb;

  /// 居保状态
  String get jbzt => _jbzt(cbzt, jfzt);

  String get sex => _sex(xb);

  String aac009;

  /// 户籍性质
  String get hjxz => _hjxz(aac009);

  /// 应缴年限
  int get yjnx {
    var birthDay = '${this.birthDay}';
    var year = int.parse(birthDay.substring(0, 4));
    var month = int.parse(birthDay.substring(4, 6));
    year = year - 1951;
    if (year >= 15) {
      return 15;
    } else if (year < 0) {
      return 0;
    } else if (year == 0) {
      if (month >= 7) return 1;
      return 0;
    } else {
      return year;
    }
  }

  /// 实缴年限
  int get sjnx => int.parse(gjnx);
}

String _jbzt(String cbzt, String jfzt) {
  switch (jfzt) {
    case '3':
      switch (cbzt) {
        case '1':
          return '正常待遇人员';
        case '2':
          return '暂停待遇人员';
        case '4':
          return '终止参保人员';
        default:
          return '其他终止缴费人员';
      }
      break;
    case '1':
      switch (cbzt) {
        case '1':
          return '正常缴费人员';
        default:
          return '其他参保缴费人员';
      }
      break;
    case '2':
      switch (cbzt) {
        case '2':
          return '暂停缴费人员';
        default:
          return '其他暂停缴费人员';
      }
      break;
    default:
      return '其他未知类型人员';
  }
}

String _sex(String xb) {
  switch (xb) {
    case '1':
      return '男';
    case '2':
      return '女';
    default:
      return '未知性别';
  }
}

String _hjxz(String code) {
  switch (code) {
    case '20':
      return '农村户籍';
    case '10':
      return '城市户籍';
    default:
      return '未知户籍';
  }
}

class DyfhQuery extends PageParameters {
  String aaf013 = '', aaf030 = '';

  @Json(name: 'aae016')
  String shzt = '';

  String aae011 = '', aae036 = '', aae036s = '';
  String aae014 = '', aae015 = '', aae015s = '';

  @Json(name: 'aae015')
  String qsshsj = '';

  @Json(name: 'aae015s')
  String jzshsj = '';

  String aac009 = '', aac003 = '';

  @Json(name: 'aac002')
  String idcard = '';

  DyfhQuery(
      {this.idcard = '',
      this.shzt = '0',
      this.qsshsj = '',
      this.jzshsj = '',
      int page = 1,
      int pagesize = 500,
      List sorting = const [
        {"dataKey": "aaa027", "sortDirection": "ascending"}
      ]})
      : super('dyfhQuery', page: page, pageSize: pagesize, sorting: sorting);
}

class Dyfh extends Data with PersionInfo {
  /// 实际待遇开始月份
  @Json(name: 'aic160')
  int payMonth;

  /// 到龄日期
  @Json(name: 'aic162')
  int retireDate;

  /// 月养老金
  @Json(name: 'aic166')
  num payAmount;

  /// 财务月份
  @Json(name: 'aae211')
  int accountMonth;

  /// 行政区划
  @Json(name: 'aaa027')
  String xzqh;

  /// 单位名称
  @Json(name: 'aaa129')
  String dwmc;

  int aaz170, aaz159, aaz157;

  Match get paymentInfo {
    var escape = (data) {
      return htmlEscape.convert('$data');
    };
    var path = '/hncjb/reports?method=htmlcontent&name=yljjs&'
        'aaz170=${escape(aaz170)}&aaz159=${escape(aaz159)}&aac001=${escape(grbh)}&'
        'aaz157=${escape(aaz157)}&aaa129=${escape(dwmc)}&aae211=${escape(accountMonth)}';
    var sock = SyncSocket(conf['host'], conf['port']);
    try {
      var content = sock.getHttp(path);
      return RegExp(regexPaymentInfo).firstMatch(content);
    } finally {
      sock.close();
    }
  }

  String bz = '', fpName = '', fpType = '', fpDate = '';
}

class BankInfoQuery extends Parameters {
  /// 身份证号码
  @Json(name: "aac002")
  String idcard = "";

  BankInfoQuery(this.idcard) : super('executeSncbgrBankinfoConQ');
}

class BankInfo extends Data {
  /// 银行类型
  @Json(name: 'bie013')
  String bankType;

  /// 户名
  @Json(name: 'aae009')
  String name;

  /// 卡号
  @Json(name: 'aae010')
  String cardNumber;

  String get bankName => _getBankName(bankType);
}

String _getBankName(String bankType) {
  switch (bankType) {
    case "LY":
      return "中国农业银行";
    case "ZG":
      return "中国银行";
    case "JS":
      return "中国建设银行";
    case "NH":
      return "农村信用合作社";
    case "YZ":
      return "邮政";
    case "JT":
      return "交通银行";
    case "GS":
      return "中国工商银行";
  }
  return "";
}

/// 省内参保缴费信息查询
class SncbqkcxjfxxQuery extends PageParameters {
  /// 身份证号码
  @Json(name: "aac002")
  String idcard = "";

  SncbqkcxjfxxQuery(this.idcard)
      : super('executeSncbqkcxjfxxQ', page: 1, pageSize: 500);
}

/// 缴费类型
class JfType extends StringMappingField {
  JfType()
      : super({
          '10': '正常应缴',
          '31': '补缴',
        });
}

/// 缴费项目
class JfItem extends StringMappingField {
  JfItem()
      : super({
          '1': '个人缴费',
          '3': '省级财政补贴',
          '4': '市级财政补贴',
          '5': '县级财政补贴',
          '11': '政府代缴',
        });
}

/// 缴费方式
class JfMethod extends StringMappingField {
  JfMethod()
      : super({
          '2': '银行代收',
          '3': '经办机构自收',
        });
}

/// 省内参保缴费信息
class Sncbqkcxjfxx extends Data {
  /// 缴费年度
  @Json(name: 'aae003')
  int year;

  /// 备注
  @Json(name: 'aae013')
  String memo;

  /// 金额
  @Json(name: 'aae022')
  num amount;

  @Json(name: 'aaa115')
  JfType type;

  @Json(name: 'aae341')
  JfItem item;

  @Json(name: 'aab033')
  JfMethod method;

  /// 划拨日期
  @Json(name: 'aae006')
  String transferDate;

  /// 是否已划拨
  bool get isTransfered => transferDate != null;

  /// 社保机构
  @Json(name: 'aaa027')
  String agency;

  /// 行政区划代码
  @Json(name: 'aaf101')
  String xzqh;
}

/// 财务支付管理查询
class CwzfglQuery extends PageParameters {
  String aaa121 = '', aaz031 = '';

  @Json(name: 'aae002')
  String yearMonth;

  @Json(name: 'aae089')
  String state;

  String bie013 = '';

  CwzfglQuery(this.yearMonth, this.state)
      : super('cwzfglQuery', page: 1, pageSize: 1000, totals: [
          {"dataKey": "aae169", "aggregate": "sum"}
        ]);
}

class Cwzfgl extends Data {
  /// 支付对象类型: "3" - 个人支付
  @Json(name: 'aaa079')
  String type;

  /// 支付单号
  @Json(name: 'aaz031')
  int paymentNO;

  /// 支付状态
  @Json(name: 'aae088')
  String state;

  /// 业务类型: "F10004" - 重复缴费退费; "F10007" - 缴费调整退款; "F10006" - 享受终止退保
  @Json(name: 'aaa121')
  String paymentType;

  /// 发放年月
  @Json(name: 'aae002')
  int yearMonth;

  /// 支付对象银行户名
  @Json(name: 'aae009')
  String paidName;

  /// 支付对象编码（身份证号码）
  @Json(name: 'bie013')
  String code;

  /// 支付对象银行账号
  @Json(name: 'aae010')
  String paidAccount;
}

class CwzfglZfdryQuery extends PageParameters {
  CwzfglZfdryQuery(
      {this.paymentNO = '',
      this.yearMonth = '',
      this.state = '',
      this.paymentType = ''})
      : super('cwzfgl_zfdryQuery', page: 1, pageSize: 1000, totals: [
          {"dataKey": "aae019", "aggregate": "sum"}
        ]);

  String aaf015 = '';

  /// 身份证号码
  @Json(name: "aac002")
  String idcard = "";

  @Json(name: "aac003")
  String name = "";

  /// 支付单号
  @Json(name: 'aaz031')
  String paymentNO;

  /// 支付状态
  @Json(name: 'aae088')
  String state;

  /// 业务类型: "F10004" - 重复缴费退费; "F10007" - 缴费调整退款; "F10006" - 享受终止退保
  @Json(name: 'aaa121')
  String paymentType;

  /// 发放年月
  @Json(name: 'aae002')
  String yearMonth;
}

class CwzfglZfdry extends Data with PersionInfo, Address {
  /// 支付单号
  @Json(name: 'aaz031')
  int payList;

  /// 支付总金额
  @Json(name: 'aae019')
  num paidAmount;

  /// 业务类型: "F10004" - 重复缴费退费; "F10007" - 缴费调整退款; "F10006" - 享受终止退保
  @Json(name: 'aaa121')
  String paymentType;

  String get paymentTypeCh {
    switch (paymentType) {
      case "F10004":
        return "重复缴费退费";
      case "F10006":
        return "享受终止退保";
      case "F10007":
        return "缴费调整退款";
    }
    return "";
  }
}

abstract class ZzfhPerInfoList {
  String aaf013 = '', aaf030 = '', aae016 = '';
  String aae011 = '', aae036 = '', aae036s = '';
  String aae014 = '', aae015 = '', aae015s = '';

  /// 身份证号码
  @Json(name: "aac002")
  String idcard = "";

  String aac003 = '', aac009 = '', aae0160 = '';
}

class CbzzfhPerInfoListQuery extends PageParameters with ZzfhPerInfoList {
  CbzzfhPerInfoListQuery(String idcard) : super('cbzzfhPerInfoList') {
    this.idcard = idcard;
  }
}

class CbzzfhPerInfoList extends Data with PersionInfo, Address {
  /// 终止年月
  @Json(name: 'aae031')
  String zzny;

  /// 审核日期
  @Json(name: 'aae015')
  String shrq;

  int aaz038, aac001;
  String aae160;
}

class CbzzfhPerInfoQuery extends Parameters {
  CbzzfhPerInfoQuery(CbzzfhPerInfoList list)
      : aaz038 = '${list.aaz038}',
        aac001 = '${list.aac001}',
        aae160 = '${list.aae160}',
        super('cbzzfhPerinfo');

  String aaz038, aac001, aae160;
}

class CbzzfhPerInfo extends Data {
  /// 终止原因
  @Json(name: 'aae160')
  String reason;

  /// 银行类型
  @Json(name: 'aaz065')
  String bankType;

  String get reasonCh => _getZzReasonChn(reason);

  String get bankName => _getBankName(bankType);
}

String _getZzReasonChn(String reason) {
  switch (reason) {
    case "1401":
      return "死亡";
    case "1406":
      return "出外定居";
    case "1407":
      return "参加职保";
    case "1499":
      return "其他原因";
    case "6401":
      return "死亡";
    case "6406":
      return "出外定居";
    case "6407":
      return "参加职保";
    case "6499":
      return "其他原因";
  }
  return "";
}

class DyzzfhPerInfoListQuery extends PageParameters with ZzfhPerInfoList {
  DyzzfhPerInfoListQuery(String idcard) : super('dyzzfhPerInfoList') {
    this.idcard = idcard;
  }

  String aic301 = '';
}

class DyzzfhPerInfoList extends Data with PersionInfo, Address {
  /// 终止年月
  @Json(name: 'aae031')
  String zzny;

  /// 审核日期
  @Json(name: 'aae015')
  String shrq;

  int aaz176;
}

class DyzzfhPerInfoQuery extends Parameters {
  DyzzfhPerInfoQuery(DyzzfhPerInfoList list)
      : aaz176 = '${list.aaz176}',
        super('dyzzfhPerinfo');

  String aaz176;
}

class DyzzfhPerInfo extends CbzzfhPerInfo {}

/// 代发人员名单查询
class DfrymdQuery extends PageParameters {
  String aaf013 = '', aaf030 = '';

  /// 居保参保状态
  @Json(name: 'aae100')
  String cbState;

  String aac002 = '', aac003 = '';

  /// 代发状态
  @Json(name: 'aae116')
  String dfState;

  String aac082 = '';

  /// 代发类型
  @Json(name: 'aac066')
  String type;

  DfrymdQuery(this.type, this.cbState, this.dfState,
      {int page = 1,
      int pageSize = 500,
      List sorting = const [
        {"dataKey": "aaf103", "sortDirection": "ascending"}
      ]})
      : super('executeDfrymdQuery',
            page: page, pageSize: pageSize, sorting: sorting);
}

String _getJbStateChn(String state) {
  switch (state) {
    case "1":
      return "正常参保";
    case "2":
      return "暂停参保";
    case "3":
      return "未参保";
    case "4":
      return "终止参保";
  }
  return "";
}

class Dfrymd extends Data with BaseInfo, Region {
  /// 代发开始年月
  @Json(name: 'aic160')
  int startYearMonth;

  /// 代发标准
  @Json(name: 'aae019')
  num standard;

  /// 代发类型
  @Json(name: 'aac066s')
  String type;

  /// 代发状态
  @Json(name: 'aae116')
  String dfState;

  /// 居保状态
  @Json(name: 'aac008s')
  String jbState;

  /// 代发截至成功发放年月
  @Json(name: 'aae002jz')
  int endYearMonth;

  /// 代发截至成功发放金额
  @Json(name: 'aae019jz')
  num totalSum;

  String get jbStateChn => _getJbStateChn(jbState);

  static String getTypeName(String type) {
    switch (type) {
      case "801":
        return "独生子女";
      case "802":
        return "乡村教师";
      case "803":
        return "乡村医生";
      case "807":
        return "电影放映员";
    }
    return "";
  }
}

/// 代发支付单查询
class DfpayffzfdjQuery extends PageParameters {
  /// 代发类型
  @Json(name: 'aaa121')
  String type;

  /// 支付单号
  @Json(name: 'aaz031')
  String payList = '';

  /// 发放年月
  @Json(name: 'aae002')
  String yearMonth;

  @Json(name: 'aae089')
  String state;

  DfpayffzfdjQuery(this.type, this.yearMonth, {this.state = '0'})
      : super('dfpayffzfdjQuery');
}

class Dfpayffzfdj extends Data {
  /// 业务类型中文名
  @Json(name: 'aaa121')
  String typeChn;

  /// 付款单号
  @Json(name: 'aaz031')
  int payList;

  static String otherPayTypeChn(String type) {
    switch (type) {
      case "DF0001":
        return "独生子女";
      case "DF0002":
        return "乡村教师";
      case "DF0003":
        return "乡村医生";
      case "DF0007":
        return "电影放映员";
    }
    return "";
  }
}

/// 代发支付单明细查询
class DfpayffzfdjmxQuery extends PageParameters {
  /// 付款单号
  @Json(name: 'aaz031')
  String payList;

  DfpayffzfdjmxQuery(int payList, {int page = 1, int pageSize = 500})
      : super('dfpayffzfdjmxQuery', page: page, pageSize: pageSize) {
    this.payList = '$payList';
  }
}

class Dfpayffzfdjmx extends Data with BaseInfo, Region {
  /// 支付标志
  @Json(name: 'aae117')
  String flag;

  /// 发放年月
  @Json(name: 'aae002')
  int yearMonth;

  /// 付款单号
  @Json(name: 'aaz031')
  int payList;

  /// 个人单号
  @Json(name: 'aaz220')
  int perPayList;

  /// 支付总金额
  @Json(name: 'aae019')
  num payAmount;
}

/// 代发支付单明细查询
class DfpayffzfdjgrmxQuery extends PageParameters {
  /// 个人编号
  @Json(name: 'aac001')
  String grbh;

  /// 付款单号
  @Json(name: 'aaz031')
  String payList;

  /// 个人单号
  @Json(name: 'aaz220')
  String perPayList;

  DfpayffzfdjgrmxQuery(int grbh, int payList, int perPayList,
      {int page = 1, int pageSize = 500})
      : super('dfpayffzfdjgrmxQuery', page: page, pageSize: pageSize) {
    this.grbh = '$grbh';
    this.payList = '$payList';
    this.perPayList = '$perPayList';
  }
}

class Dfpayffzfdjgrmx extends Data {
  /// 待遇日期
  @Json(name: 'aae003')
  int pensionDate;

  /// 支付标志
  @Json(name: 'aae117')
  String flag;

  /// 发放年月
  @Json(name: 'aae002')
  int yearMonth;

  /// 付款单号
  @Json(name: 'aaz031')
  int payList;

  /// 支付总金额
  @Json(name: 'aae019')
  num payAmount;
}

const _xzqhMap = {
  "43030200": "代发虚拟乡镇",
  "43030201": "长城乡",
  "43030202": "昭潭街道",
  "43030203": "先锋街道",
  "43030204": "万楼街道",
  "43030205": "（原）鹤岭镇",
  "43030206": "楠竹山镇",
  "43030207": "姜畲镇",
  "43030208": "鹤岭镇",
  "43030209": "城正街街道",
  "43030210": "雨湖路街道",
  "43030211": "（原）平政路街道",
  "43030212": "云塘街道",
  "43030213": "窑湾街道",
  "43030214": "（原）窑湾街道",
  "43030215": "广场街道",
  "43030216": "（原）羊牯塘街道"
};

/// 待遇暂停查询
class PausePaymentQuery extends PageParameters {
  String aaf013 = '', aaz070 = '';

  /// 身份证号码
  @Json(name: "aac002")
  String idcard = "";

  String aae141 = '', aae141s = '';

  /// 审核状态: '1' - 已审核; '0' - 未审核
  @Json(name: "aae016")
  String audited = "";

  String aae036 = '', aae036s = '', aac009 = '';

  String aae015 = '', aae015s = '', aae116 = '';

  PausePaymentQuery(this.idcard, [this.audited = ''])
      : super('queryAllPausePersonInfosForAuditService');
}

class PausePayment extends Data with BaseInfo {
  /// 暂停时间
  @Json(name: 'aae141')
  int time;

  /// 暂停原因
  @Json(name: 'aae160')
  String reason;

  /// 备注
  @Json(name: 'aae013')
  String memo;

  String get reasonChn => _pausePaymentChn(reason);
}

String _pausePaymentChn(String reason) {
  switch (reason) {
    case "1299":
      return "其他原因暂停养老待遇";
    case "1200":
      return "养老保险待遇暂停";
    case "1201":
      return "养老待遇享受人员未提供生存证明";
    default:
      return '其它未知类型${reason}';
  }
}

/// 疑似死亡
class SuspiciousDeathQuery extends PageParameters {
  String aac003 = '', aae037s = '', aae037e = '';

  /// 身份证号码
  @Json(name: "aac002")
  String idcard = "";

  String aaf013 = '', aaf101 = '', aac008 = '';
  String hsbz = '';

  SuspiciousDeathQuery(this.idcard) : super('dsznswcxQuery');
}

class SuspiciousDeath extends Data with BaseInfo {
  @Json(name: 'aae036')
  String compareTime;

  @Json(name: 'aae037')
  int deathTime;

  @Json(name: 'aac008')
  String jbzt;

  @Json(name: 'bz')
  String memo;
}
