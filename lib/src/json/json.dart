import 'dart:mirrors';

class Json {
  final String name;
  final bool ignored;

  const Json({this.name, this.ignored});
}

class JsonSerializer<T> {
  T fromJson(String json) {
    var mirror = (reflectType(T) as ClassMirror).newInstance(Symbol(''), []);
    
  }
}