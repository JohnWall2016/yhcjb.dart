import 'dart:mirrors';
import 'package:xml/xml.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:yhcjb/src/json/json.dart';
import '../xml/node.dart';
import '../xml/xml.dart';
import '../net/sync_socket.dart';
import './_config.dart';

class Session extends SyncSocket {
  String _userId;
  String _password;
  String _sessionId;

  Session(String host, int port, String userId, String password)
      : _userId = userId,
        _password = password,
        super(host, port, encoding: gbk);

  String get url => '${host}:{port}';

  void _request(String content) {
    var request =
        HttpRequest('/sbzhpt/MainServlet', method: 'POST', encoding: gbk)
          ..addHeader('SOAPAction', 'mainservlet')
          ..addHeader('Content-Type', 'text/html;charset=GBK')
          ..addHeader('Host', url)
          ..addHeader('Connection', 'Keep-Alive')
          ..addHeader('Cache-Control', 'no-cache');
    if (_sessionId != null) {
      request.addHeader('Cookie', 'JSESSIONID=$_sessionId');
    }
    request.addBody(content);
    write(request.toBytes());
  }

  void sendEnvelop<T extends Request>({T request, String funid}) {
    var en = RequestEnvelop(_userId, _password, request: request, funid: funid);
    _request(en.toXmlString());
  }

  ResponseEnvelop<ResponseHeader, T> getEnvelop<T extends Response>() {
    return ResponseEnvelop.fromXmlString(readHttpBody());
  }

  ResponseEnvelop<LoginHeader, LoginResponse> login() {
    sendEnvelop(
        funid: 'F00.00.00.00|192.168.1.110|PC-20170427DGON|00-05-0F-08-1A-34');
    var header = readHttpHeader();
    var cookies = header['set-cookie'];
    if (cookies != null) {
      for (var cookie in cookies) {
        var match = RegExp("JSESSIONID=(.+?);").firstMatch(cookie);
        if (match != null) {
          _sessionId = match.group(1);
          break;
        }
      }
    }
    return loginInfo =
        ResponseEnvelop.fromXmlString<LoginHeader, LoginResponse>(
            readHttpBody(header));
  }

  void logout() {
    // TODO
  }

  ResponseEnvelop<LoginHeader, LoginResponse> loginInfo;

  static void use(void Function(Session) action, {String user = 'sj'}) {
    var session = Session(netconf['host'], netconf['port'],
        netconf['users'][user]['id'], netconf['users'][user]['pwd']);
    try {
      session.login();
      action(session);
      session.logout();
    } finally {
      session.close();
    }
  }
}

class Xml {
  final String name;
  final bool ignored;
  const Xml({this.name, this.ignored});
}

class Paramable {
  Iterable<Node> toNodes() sync* {
    var map = <String, String>{};
    InstanceMirror inst = reflect(this);
    _toMap(inst, inst.type, map);
    for (var key in map.keys) {
      yield Element('para', {key: map[key]});
    }
  }

  void _toMap(InstanceMirror inst, ClassMirror clazz, Map<String, String> map) {
    if (!clazz.isSubtypeOf(reflectType(Paramable))) return;

    _toMap(inst, clazz.superclass, map);

    clazz.declarations.values.forEach((decl) {
      if (decl is VariableMirror) {
        String name;
        var meta = decl.metadata.firstWhere(
            (metadataMirror) => metadataMirror.reflectee is Xml,
            orElse: () => null);
        if (meta != null) {
          Xml xml = meta.reflectee;
          if (xml.ignored != null && xml.ignored) {
            return;
          } else if (xml.name != null && xml.name.isNotEmpty) {
            name = xml.name;
          }
        }
        name ??= MirrorSystem.getName(decl.simpleName);
        var obj = inst.getField(decl.simpleName).reflectee;
        if (obj != null) {
          map[name] = obj.toString();
        }
      }
    });
  }
}

class RequestHeader extends Paramable {
  final String usr, pwd, funid;
  RequestHeader({this.usr, this.pwd, this.funid});
}

class Request extends Paramable {
  @Xml(ignored: true)
  final String funid;

  final String functionid;
  Request(this.funid, this.functionid);

  String createSql(Map<String, String> props) {
    String sql;
    for (var key in props.keys) {
      var value = props[key];
      if (value != null) {
        if (sql == null) {
          sql = '$key = &apos;$value&apos;';
        } else {
          sql += ' AND $key = &apos;$value&apos;';
        }
      }
    }
    if (sql != null) {
      sql = '( $sql)';
    }
    return sql;
  }
}

class RequestEnvelop<T extends Request> {
  RequestHeader header;
  T body;

  RequestEnvelop(String usr, String pwd, {T request, String funid}) {
    if (request != null) {
      this.header = RequestHeader(usr: usr, pwd: pwd, funid: request.funid);
      this.body = request;
    } else {
      this.header = RequestHeader(usr: usr, pwd: pwd, funid: funid);
    }
  }

  XmlNode toXml() {
    return (Element('soap:Envelope', {
      'xmlns:soap': 'http://schemas.xmlsoap.org/soap/envelope/',
      'soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/'
    })
          ..children.add(Element('soap:Header')
            ..children.add(
                Element('in:system', {'xmlns:in': 'http://www.molss.gov.cn/'})
                  ..children.addAll(header.toNodes())))
          ..children.add(Element('soap:Body')
            ..children.add(
                Element('in:business', {'xmlns:in': 'http://www.molss.gov.cn/'})
                  ..children.addAll(body?.toNodes() ?? []))))
        .toXmlNode();
  }

  String toXmlString() =>
      '<?xml version="1.0" encoding="GBK"?>' + toXml().toXmlString();
}

final ResultableType = reflectType(Resultable);

final NumType = reflectType(num);

abstract class CustomField<T> {
  T value;
}

abstract class MappingField<F, T> extends CustomField<F> {
  Map<F, T> mapping;
  String Function() notMatch;

  MappingField(Map<F, T> mapping, {String notMatch()}) {
    this.mapping = mapping ?? {};
    this.notMatch = notMatch ?? () => 'NotMatch: $value';
  }

  T map(F value) => mapping[value];

  @override
  String toString() => '${map(value) ?? notMatch()}';
}

final CustomFieldType = reflectType(CustomField);

class Resultable extends Jsonable {
  static Map<String, dynamic> convert(XmlNode node) {
    var map = <String, dynamic>{};
    for (var node in node?.children ?? []) {
      if (node is XmlElement) {
        if (node.name.local == 'result') {
          for (var attr in node.attributes) {
            map[attr.name.local] = attr.value;
            break;
          }
        } else if (node.name.local == 'resultset') {
          String key = getAttribute(node, 'name');
          if (key != null) {
            map[key] = [];
            node.children.forEach((n) {
              if (n is XmlElement) {
                if (n.name.local == 'row') {
                  var rowmap = <String, String>{};
                  for (var attr in n.attributes) {
                    rowmap[attr.name.local] = attr.value;
                  }
                  map[key].add(rowmap);
                }
              }
            });
          }
        }
      }
    }
    return map;
  }

  static T fromNode<T extends Resultable>(XmlNode node) {
    var map = convert(node);
    var clazz = reflectType(T) as ClassMirror;
    var inst = clazz.newInstance(Symbol(''), []);
    _fromMap(map, inst, clazz);
    return inst.reflectee;
  }

  static _fromMap(
      Map<String, dynamic> map, InstanceMirror inst, ClassMirror clazz) {
    if (!clazz.isSubtypeOf(ResultableType)) return;

    _fromMap(map, inst, clazz.superclass);

    clazz.declarations.values.forEach((decl) {
      if (decl is VariableMirror) {
        String name;
        var meta = decl.metadata.firstWhere(
            (metadataMirror) => metadataMirror.reflectee is Xml,
            orElse: () => null);
        if (meta != null) {
          Xml xml = meta.reflectee;
          if (xml.ignored != null && xml.ignored) {
            return;
          } else if (xml.name != null && xml.name.isNotEmpty) {
            name = xml.name;
          }
        }
        Symbol sName = decl.simpleName;
        name ??= MirrorSystem.getName(sName);
        if (map.containsKey(name)) {
          var value = map[name];
          if (value == null) {
            inst.setField(sName, value);
            return;
          }
          var type = decl.type;
          if (value is List && type.simpleName == #List) {
            var argType =
                type.typeArguments.isNotEmpty ? type.typeArguments.first : null;
            if (argType != null &&
                argType.simpleName != #dynamic &&
                argType.isSubtypeOf(ResultableType)) {
              var listMirror =
                  reflectType(List, [argType.reflectedType]) as ClassMirror;
              var list = listMirror.newInstance(Symbol(''), []);
              value.forEach((v) {
                var argClazz = (argType as ClassMirror);
                var argInst = argClazz.newInstance(Symbol(''), []);
                Resultable._fromMap(v, argInst, argClazz);
                list.reflectee.add(argInst.reflectee);
              });
              inst.setField(sName, list.reflectee);
              return;
            }
          }
          if (value is Map && type.isSubtypeOf(ResultableType)) {
            var argClazz = (type as ClassMirror);
            var argInst = argClazz.newInstance(Symbol(''), []);
            Resultable._fromMap(value, argInst, argClazz);
            inst.setField(sName, argInst.reflectee);
          } else if (reflectType(value.runtimeType).isAssignableTo(type)) {
            inst.setField(sName, value);
          } else if (value is String && type.isSubtypeOf(NumType)) {
            var n = num.tryParse(value);
            if (n != null) {
              inst.setField(sName, n);
            }
          } else if (type.isSubtypeOf(CustomFieldType)) {
            var argInst = (type as ClassMirror).newInstance(Symbol(''), []);
            argInst.setField(Symbol('value'), value);
            inst.setField(sName, argInst.reflectee);
          }
        }
      }
    });
  }
}

class ResponseHeader extends Resultable {
  String sessionID, message;
}

class LoginHeader extends Resultable {
  String sessionID, username, producttype;
}

class Acl extends Resultable {
  String id;
}

class LoginResponse extends Response {
  String passwd;

  /// 单位名称
  @Xml(name: 'sab090')
  String dwmc;

  String userid;

  String usr;

  @Xml(name: 'operator_name')
  String operatorName;

  String pwd;

  @Xml(name: 'login_name')
  String loginName;

  List<Acl> acl;
}

class Response extends Resultable {
  String result;
}

class ResponseEnvelop<S extends Resultable, T extends Response> {
  S header;
  T body;

  ResponseEnvelop();

  static ResponseEnvelop<S, T>
      fromXmlDocument<S extends Resultable, T extends Response>(
          XmlDocument doc) {
    if (doc != null) {
      var env = findChild(doc, 'Envelope');
      if (env != null) {
        var res = ResponseEnvelop<S, T>();
        var header = findChild(env, 'Header');
        if (header != null) {
          var system = findChild(header, 'system');
          res.header = Resultable.fromNode<S>(system ?? header);
        }
        var body = findChild(env, 'Body');
        if (body != null) {
          var business = findChild(body, 'business');
          if (business != null) {
            res.body = Resultable.fromNode<T>(business);
          }
        }
        return res;
      }
    }
    return null;
  }

  static ResponseEnvelop<S, T>
      fromXmlString<S extends Resultable, T extends Response>(String xml) {
    return ResponseEnvelop.fromXmlDocument(parse(xml));
  }
}

class SncbrycxRequest extends Request {
  int startrow = 1;
  int row_count = -1;
  int pagesize = 500;
  String clientsql;

  SncbrycxRequest({String idcard, String name}) : super('F00.01.03', 'F27.06') {
    clientsql = createSql({
      'c.aac002': idcard,
      'c.aac003': name,
    });
  }
}

/// 参保状态
class Cbzt extends MappingField<String, String> {
  Cbzt()
      : super({
          '1': '参保缴费',
          '2': '暂停缴费',
          '3': '终止缴费',
        });
}

/// 社会保险状态
class Shbxzt extends MappingField<String, String> {
  Shbxzt()
      : super({
          '1': '在职',
          '2': '退休',
          '4': '终止',
        });
}

/// 缴费人员类别
class Jfrylx extends MappingField<String, String> {
  Jfrylx()
      : super({
          '101': '单位在业人员',
          '102': '个体缴费',
        });
}

class Sncbry extends Resultable {
  @Xml(name: 'aac003')
  String name;

  @Xml(name: 'aac002')
  String idcard;

  /// 社保机构
  @Xml(name: 'aab300')
  String sbjg;

  /// 个人编号
  @Xml(name: 'sac100')
  String personID;

  /// 单位编号
  @Xml(name: 'sab100')
  String companyID;

  @Xml(name: 'aac031')
  Cbzt cbzt;

  @Xml(name: 'aac008')
  Shbxzt shbxzt;

  @Xml(name: 'sac007')
  Jfrylx jfrylx;
}

class SncbrycxResponse extends Response {
  @Xml(name: 'querylist')
  List<Sncbry> list;

  @Xml(name: 'row_count')
  int count;
}
