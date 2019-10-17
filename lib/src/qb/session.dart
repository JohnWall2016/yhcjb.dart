import 'dart:mirrors';
import 'package:xml/xml.dart';
import '../xml/node.dart';
import '../xml/xml.dart';
import './_config.dart';

class Xml {
  final String name;
  final bool ignored;
  const Xml({this.name, this.ignored});
}

class RequestEnvelop<T extends RequestBody> {
  RequestHeader header;
  T body;

  RequestEnvelop(T body) {
    this.header = RequestHeader(funid: body.funid);
    this.body = body;
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
                  ..children.addAll(body.toNodes()))))
        .toXmlNode();
  }

  String toXmlString() => toXml().toXmlString();
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

class UserInfo extends Paramable {
  String usr, pwd;
  UserInfo(String usr, String pwd) {
    if (usr == null || pwd == null) {
      this.usr = netconf['users']['sj']['id'];
      this.pwd = netconf['users']['sj']['pwd'];
    }
  }
}

class RequestHeader extends UserInfo {
  final String funid;
  RequestHeader({usr, pwd, this.funid}) : super(usr, pwd);
}

class RequestBody extends Paramable {
  @Xml(ignored: true)
  final String funid;

  final String functionid;
  RequestBody(this.funid, this.functionid);
}

class SncbrycxRequest extends RequestBody {
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

class ResponseEnvelop<T extends ResponseBody> {
  ResponseHeader header;
  T body;

  ResponseEnvelop();

  static ResponseEnvelop<T> fromXmlDocument<T extends ResponseBody>(
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

  static ResponseEnvelop<T> fromXmlString<T extends ResponseBody>(String xml) {
    return ResponseEnvelop.fromXmlDocument(parse(xml));
  }
}

class ResponseHeader extends Resultable {
  String sessionID, message;
}

class ResponseBody extends Resultable {
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

class SncbrycxResponse extends ResponseBody {
  List<SncbrycxItem> querylist;
  int row_count;
}
