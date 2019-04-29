import './sync_socket.dart';
import '../json/json.dart';

class Session extends SyncSocket {
  String _userId;
  String _password;
  String _sessionId, _cxCookie;

  Session(String host, int port, String userId, String password)
      : _userId = userId,
        _password = password,
        super(host, port);

  HttpRequest _buildRequest(String content) {
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
    request.addBody(content);
    return request;
  }

  void request(String content) {
    var req = _buildRequest(content);
    write(req.toBytes());
  }

  void sendService(String id, Jsonable params) {
    var serv =
        Service(id: id, params: params, userId: _userId, password: _password);
    request(serv.toJson());
  }

  Result<T> getResult<T extends Jsonable>() {
    var result = readHttpBody();
    return Jsonable.fromJson<Result<T>>(result);
  }
}

class Service extends Jsonable {
  String serviceid;
  String target = '';
  String sessionid;
  String loginname;
  String password;
  Jsonable params;
  List<Jsonable> datas = [];

  Service({String id, Jsonable params, String userId, String password}) {
    serviceid = id;
    loginname = userId;
    this.password = password;
    this.params = params;
    datas.add(params);
  }
}

class Result<Data extends Jsonable> extends Jsonable {
  int rowcount, page, pagesize;
  String serviceid, type, vcode, message, messagedetail;
  List<Data> datas;

  Data operator [](int index) => datas[index];
  int get length => datas?.length ?? 0;
}
