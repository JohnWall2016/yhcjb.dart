import 'dart:mirrors';
import 'package:xml/xml.dart';
import '../xml/node.dart';
import './_config.dart';

class Xml {
  final String name;
  final bool ignored;
  const Xml({this.name, this.ignored});
}

class Envelop<T extends RequestBody> {
  Params<RequestHeader> header;
  Params<T> body;

  Envelop(T body) {
    this.header = Params(RequestHeader(funid: body.funid));
    this.body = Params(body);
  }

  XmlNode toXml() {
    return (Element('soap:Envelope', {
      'xmlns:soap': 'http://schemas.xmlsoap.org/soap/envelope/',
      'soap:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/'
    })..children.add(
      Element('soap:Header')..children.add(
        Element('in:system', {
          'xmlns:in': 'http://www.molss.gov.cn/'
        })..children.addAll(header.toNodes())
      )
    )..children.add(
      Element('soap:Body')..children.add(
        Element('in:business', {
          'xmlns:in': 'http://www.molss.gov.cn/'
        })..children.addAll(body.toNodes())
      )
    )).toXmlNode();
  }

  String toXmlString() => toXml().toXmlString();
}

abstract class Serializable{}

class Params<T> {
  final T params;

  Params(this.params);

  Iterable<Node> toNodes() sync*{
    var map = <String, String>{};
    InstanceMirror inst = reflect(this.params);
    _toMap(inst, inst.type, map);
    for (var key in map.keys) {
      yield Element('para', {
        key: map[key]
      });
    }
  }

  void _toMap(InstanceMirror inst, ClassMirror clazz, Map<String, String> map) {
    if (!clazz.isSubtypeOf(reflectType(Serializable))) return;

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

class UserInfo extends Serializable{
  String usr, pwd;
  UserInfo(String usr, String pwd) {
    if (usr == null || pwd == null) {
      this.usr = netconf['users']['sj']['id'];
      this.pwd = netconf['users']['sj']['pwd'];
    }
  }
}

class RequestHeader extends UserInfo {
  final funid;
  RequestHeader({usr, pwd, this.funid}) : super(usr, pwd);
}

class RequestBody extends Serializable {
  @Xml(ignored: true)
  final String funid;
  
  final String functionid;
  RequestBody(this.funid, this.functionid);
}

class Sncbrycx extends RequestBody {
  int startrow = 1;
  int row_count = -1;
  int pagesize = 500;
  String clientsql;

  @Xml(ignored: true)
  String idcard;

  Sncbrycx(this.idcard) : super('F00.01.03', 'F27.06') {
    clientsql = '( aac002 = &apos;$idcard&apos;)';
  }
}