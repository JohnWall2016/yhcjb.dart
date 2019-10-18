import 'dart:mirrors';
import 'package:xml/xml.dart';
import '../xml/node.dart';
import '../xml/xml.dart';
import '../net/sync_socket.dart';
import './_config.dart';

class Session extends SyncSocket {
  String _userId;
  String _password;

  Session(String host, int port, String userId, String password)
      : _userId = userId,
        _password = password,
        super(host, port);

  void _request(String content) {
    var request = HttpRequest('/hncjb/reports/crud', method: 'POST');
    // TODO
  }

  void sendEnvelop<T extends Request>({T request, String funid}) {
    var en = RequestEnvelop(_userId, _password, request: request, funid: funid);
    _request(en.toXmlString());
  }
}

class Xml {
  final String name;
  final bool ignored;
  const Xml({this.name, this.ignored});
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

  String toXmlString() => '<?xml version="1.0" encoding="GBK"?>' + toXml().toXmlString();
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
}

class SncbrycxRequest extends Request {
  int startrow = 1;
  int row_count = -1;
  int pagesize = 500;
  String clientsql;

  @Xml(ignored: true)
  String idcard;

  SncbrycxRequest(this.idcard) : super('F00.01.03', 'F27.06') {
    clientsql = '( aac002 = &apos;$idcard&apos;)';
  }
}

final ResultableType = reflectType(Resultable);
final NumType = reflectType(num);

class Resultable {
  static convert(XmlNode node) {
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
          }
        }
      }
    });
  }
}

class ResponseEnvelop<T extends Response> {
  ResponseHeader header;
  T body;

  ResponseEnvelop();

  static ResponseEnvelop<T> fromXmlDocument<T extends Response>(
      XmlDocument doc) {
    if (doc != null) {
      var env = findChild(doc, 'Envelope');
      if (env != null) {
        var res = ResponseEnvelop<T>();
        var header = findChild(env, 'Header');
        if (header != null) {
          res.header = Resultable.fromNode<ResponseHeader>(header);
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

  static ResponseEnvelop<T> fromXmlString<T extends Response>(String xml) {
    return ResponseEnvelop.fromXmlDocument(parse(xml));
  }
}

class ResponseHeader extends Resultable {
  String sessionID, message;
}

class Response extends Resultable {
  String result;
}

class SncbrycxItem extends Resultable {
  @Xml(name: 'aac003')
  String name;

  @Xml(name: 'aac002')
  String idcard;

  @Xml(name: 'aab300')
  String sbjg;
}

class SncbrycxResponse extends Response {
  List<SncbrycxItem> querylist;
  int row_count;
}
