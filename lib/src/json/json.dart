import 'dart:mirrors';
import 'dart:convert' as convert;

class Json {
  final String name;
  final bool ignored;

  const Json({this.name, this.ignored});
}

class Undefined {
  const Undefined();
}

const undefined = Undefined();

class Jsonable<T> {
  T fromMap(Map<String, dynamic> map) {
    var inst = reflect(this);

    inst.type.declarations.values.forEach((decl) {
      if (decl is VariableMirror) {
        String name;
        var meta = decl.metadata.firstWhere(
            (metadataMirror) => metadataMirror.reflectee is Json,
            orElse: () => null);
        if (meta != null) {
          Json json = meta.reflectee;
          if (json.ignored != null && json.ignored)
            return;
          else if (json.name != null && json.name.isNotEmpty) {
            name = json.name;
          }
        }
        name ??= MirrorSystem.getName(decl.simpleName);
        if (map.containsKey(name)) {
          var value = map[name];
          if (value is Map && decl.type.isSubtypeOf(reflectType(Jsonable))) {
            print(value);
            var newInst =
                (decl.type as ClassMirror).newInstance(Symbol(''), []);
            inst.setField(decl.simpleName, newInst.reflectee.fromMap(value));
          } else if (value is List &&
              decl.type.isSubtypeOf(reflectType(List)) &&
              decl.type.typeArguments[0].isSubtypeOf(reflectType(Jsonable))) {
            print(value);
            inst.setField(
                decl.simpleName,
                value.map((v) {
                  var newInst = (decl.type.typeArguments[0] as ClassMirror)
                      .newInstance(Symbol(''), []);
                  return newInst.reflectee.fromMap(v);
                }).toList());
          }
        }
      }
    });

    return inst.reflectee as T;
  }

  Map<String, dynamic> toMap() {
    InstanceMirror inst = reflect(this);
    Map<String, dynamic> map = {};

    getValue(value) {
      if (value is bool || value is num || value is String || value == null) {
        return value;
      } else if (value is List) {
        return value.map((v) => getValue(v) ?? null).toList();
      } else if (value is Jsonable) {
        return value.toMap();
      } else {
        return undefined;
      }
    }

    inst.type.declarations.values.forEach((decl) {
      if (decl is VariableMirror) {
        String name;
        var meta = decl.metadata.firstWhere(
            (metadataMirror) => metadataMirror.reflectee is Json,
            orElse: () => null);
        if (meta != null) {
          Json json = meta.reflectee;
          if (json.ignored != null && json.ignored)
            return;
          else if (json.name != null && json.name.isNotEmpty) {
            name = json.name;
          }
        }
        name ??= MirrorSystem.getName(decl.simpleName);
        var obj = inst.getField(decl.simpleName).reflectee;
        var value = getValue(obj);
        if (value != undefined) {
          map[name] = value;
        }
      }
    });

    return map;
  }
}
