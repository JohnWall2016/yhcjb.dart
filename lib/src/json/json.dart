import 'dart:mirrors';
import 'dart:convert' as convert;

class Json {
  final String name;
  final bool ignored;

  const Json({this.name, this.ignored});
}

final JsonableType = reflectType(Jsonable);

abstract class CustomField<T> {
  T value;
}

abstract class MappingField<F, T> extends CustomField<F> {
  Map<F, T> mapping;
  String Function() notMatch;

  MappingField(mapping, {notMatch}) {
    this.mapping = mapping ?? {};
    this.notMatch = notMatch ?? () => 'NotMatch: $value';
  }
  
  T map(F value) => mapping[value];

  @override
  String toString() => '${map(value) ?? notMatch()}';
}

mixin ToAlias {}

abstract class StringMappingField = MappingField<String, String> with ToAlias;

final CustomFieldType = reflectType(CustomField);

class Jsonable {
  static T fromJson<T extends Jsonable>(String json) {
    return fromMap<T>(convert.json.decode(json));
  }

  String toJson([bool rawName = false]) {
    return convert.json.encode(toMap(rawName));
  }

  static T fromMap<T extends Jsonable>(Map<String, dynamic> map) {
    var clazz = reflectType(T) as ClassMirror;
    var inst = clazz.newInstance(Symbol(''), []);
    _fromMap(map, inst, clazz);
    return inst.reflectee;
  }

  static _fromMap(
      Map<String, dynamic> map, InstanceMirror inst, ClassMirror clazz) {
    if (!clazz.isSubtypeOf(JsonableType)) return;

    _fromMap(map, inst, clazz.superclass);

    clazz.declarations.values.forEach((decl) {
      if (decl is VariableMirror) {
        String name;
        var meta = decl.metadata.firstWhere(
            (metadataMirror) => metadataMirror.reflectee is Json,
            orElse: () => null);
        if (meta != null) {
          Json json = meta.reflectee;
          if (json.ignored != null && json.ignored) {
            return;
          } else if (json.name != null && json.name.isNotEmpty) {
            name = json.name;
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
                argType.isSubtypeOf(JsonableType)) {
              var listMirror =
                  reflectType(List, [argType.reflectedType]) as ClassMirror;
              var list = listMirror.newInstance(Symbol(''), []);
              value.forEach((v) {
                var argClazz = (argType as ClassMirror);
                var argInst = argClazz.newInstance(Symbol(''), []);
                Jsonable._fromMap(v, argInst, argClazz);
                list.reflectee.add(argInst.reflectee);
              });
              inst.setField(sName, list.reflectee);
              return;
            }
          }
          if (value is Map && type.isSubtypeOf(JsonableType)) {
            var argClazz = (type as ClassMirror);
            var argInst = argClazz.newInstance(Symbol(''), []);
            Jsonable._fromMap(value, argInst, argClazz);
            inst.setField(sName, argInst.reflectee);
          } else if (reflectType(value.runtimeType).isAssignableTo(type)) {
            inst.setField(sName, value);
          } else if (type.isSubtypeOf(CustomFieldType)) {
            var argInst = (type as ClassMirror).newInstance(Symbol(''), []);
            argInst.setField(Symbol('value'), value);
            inst.setField(sName, argInst.reflectee);
          }
        }
      }
    });
  }

  Map<String, dynamic> toMap([bool rawName = false]) {
    InstanceMirror inst = reflect(this);
    Map<String, dynamic> map = {};
    _toMap(inst, inst.type, map, rawName);
    return map;
  }

  _getValue(value) {
    if (value is bool || value is num || value is String || value == null) {
      return value;
    } else if (value is Jsonable) {
      return value.toMap();
    } else if (value is List) {
      return value.map((v) => _getValue(v)).toList();
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k, _getValue(v)));
    } else {
      return value.toString();
    }
  }

  void _toMap(InstanceMirror inst, ClassMirror clazz, Map<String, dynamic> map,
      [bool rawName = false]) {
    if (!clazz.isSubtypeOf(reflectType(Jsonable))) return;

    _toMap(inst, clazz.superclass, map, rawName);

    clazz.declarations.values.forEach((decl) {
      if (decl is VariableMirror) {
        String name;
        if (!rawName) {
          var meta = decl.metadata.firstWhere(
              (metadataMirror) => metadataMirror.reflectee is Json,
              orElse: () => null);
          if (meta != null) {
            Json json = meta.reflectee;
            if (json.ignored != null && json.ignored) {
              return;
            } else if (json.name != null && json.name.isNotEmpty) {
              name = json.name;
            }
          }
        }
        name ??= MirrorSystem.getName(decl.simpleName);
        var obj = inst.getField(decl.simpleName).reflectee;
        var value = _getValue(obj);
        map[name] = value;
      }
    });
  }
}
