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

  _createRequest() {
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

  Result<T> getResult<T extends Jsonable>() {
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
  final int page, pagesize;
  final List filtering = [];
  final List sorting = [];
  final List totals = [];

  PageParameters(String id, {this.page = 1, this.pagesize = 15}) : super(id);

  void addFiltering(Map filtering) => this.sorting.add(filtering);

  void addSorting(Map sorting) => this.sorting.add(sorting);

  void addTotals(Map totals) => this.totals.add(totals);
}

class Result<Data extends Jsonable> extends Jsonable {
  int rowcount, page, pagesize;
  String serviceid, type, vcode, message, messagedetail;
  List<Data> datas;

  Data operator [](int index) => datas[index];
  int get length => datas?.length ?? 0;
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

/// 个人综合信息
class Grinfo extends Jsonable {
  /// 个人编号
  @Json(name: "aac001")
  int grbh;

  /// 身份证号码
  @Json(name: "aac002")
  String idcard;

  @Json(name: "aac003")
  String name;

  @Json(name: "aac006")
  int birthday;

  /// 参保状态: "1"-正常参保 "2"-暂停参保 "4"-终止参保 "0"-未参保
  @Json(name: "aac008")
  String cbzt;

  /// 户口所在地
  @Json(name: "aac010")
  String hkszd;

  /// 缴费状态: "1"-参保缴费 "2"-暂停缴费 "3"-终止缴费
  @Json(name: "aac031")
  String jfzt;

  @Json(name: "aae005")
  String phone;

  @Json(name: "aae006")
  String address;

  @Json(name: "aae010")
  String bankcard;

  /// 行政区划编码
  @Json(name: "aaf101")
  String xzqh;

  /// 村组名称
  @Json(name: "aaf102")
  String czmc;

  /// 村社区名称
  @Json(name: "aaf103")
  String csmc;
}
