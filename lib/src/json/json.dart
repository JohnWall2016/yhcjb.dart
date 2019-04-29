import 'dart:mirrors';
import 'dart:convert' as convert;

class Json {
  final String name;
  final bool ignored;

  const Json({this.name, this.ignored});
}

class Jsonable<T> {
  static T fromJson<T>(String json) {
    return fromMap(convert.json.decode(json));
  }

  String toJson() {
    return convert.json.encode(toMap());
  }

  static T fromMap<T>(Map<String, dynamic> map) {
    return _fromMap(map, reflectType(T));
  }

  static _fromMap(Map<String, dynamic> map, ClassMirror klass) {
    var inst = klass.newInstance(Symbol(''), []);

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
          var simpleName = decl.simpleName;
          TypeMirror argType;
          if (value == null) {
            inst.setField(simpleName, value);
            return;
          }
          var type = decl.type;
          if (value is List &&
              type.simpleName == #List &&
              (argType = type.typeArguments.isNotEmpty
                      ? type.typeArguments.first
                      : null) !=
                  null &&
              argType.isSubtypeOf(reflectType(Jsonable))) {
            var listMirror = reflectType(List, [argType.reflectedType]);
            var list = (listMirror as ClassMirror).newInstance(Symbol(''), []);
            value.forEach((v) {
              list.reflectee.add(Jsonable._fromMap(v, argType));
            });
            inst.setField(simpleName, list.reflectee);
          } else if (value is Map && type.isSubtypeOf(reflectType(Jsonable))) {
            inst.setField(simpleName, Jsonable._fromMap(value, type));
          } else if (reflectType(value.runtimeType).isAssignableTo(type)) {
            inst.setField(simpleName, value);
          }
        }
      }
    });

    return inst.reflectee;
  }

  Map<String, dynamic> toMap() {
    InstanceMirror inst = reflect(this);
    Map<String, dynamic> map = {};

    getValue(value) {
      if (value is bool || value is num || value is String || value == null) {
        return value;
      } else if (value is List) {
        return value.map((v) => getValue(v)).toList();
      } else if (value is Jsonable) {
        return value.toMap();
      } else {
        return null;
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
        map[name] = value;
      }
    });

    return map;
  }
}
