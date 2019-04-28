import 'dart:mirrors';
import 'dart:convert' as convert;

class Json {
  final String name;
  final bool ignored;

  const Json({this.name, this.ignored});
}

class JsonSerializer<T> {
  T fromJson(String json) {
    var mirror = (reflectType(T) as ClassMirror).newInstance(Symbol(''), []);

  }

  String toJson() {
    InstanceMirror inst = reflect(this);
    Map json = {};

    inst.type.declarations.values.forEach((decl) {
      
    });
    
    return convert.json.encode(json);
  }
}