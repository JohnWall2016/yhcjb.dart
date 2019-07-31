import 'dart:mirrors';
import 'dart:io';

import 'package:mysql1/mysql1.dart';
export 'package:mysql1/mysql1.dart';

import 'package:xlsx_decoder/xlsx_decoder.dart';

import '../util/util.dart';

class Database {
  MySqlConnection _conn;

  Database._(this._conn);

  static Future<Database> connect(
      {String host, int port, String user, String password, String db}) async {
    return Database._(await MySqlConnection.connect(new ConnectionSettings(
        host: host, port: port, user: user, password: password, db: db)));
  }

  Map<String, dynamic> _models = {};

  Model<T> getModel<T>(String name) {
    if (_models.containsValue(name)) {
      return _models[name];
    } else {
      var model = Model<T>._(this, name);
      _models[name] = model;
      return model;
    }
  }

  Future close() async {
    return await _conn.close();
  }

  Future<Results> query(String sql, [List<Object> values]) async =>
      _conn.query(sql, values);

  Future execSql(String sql) async {
    return await _conn.query(sql);
  }
}

class Field {
  final String name;
  final bool primaryKey;
  final bool autoIncrement;
  final bool notNull;
  const Field(
      {this.name,
      this.primaryKey = false,
      this.autoIncrement = false,
      this.notNull = false});
}

class Model<T> {
  Database _db;

  Future close() async {
    return await _db?.close();
  }

  ClassMirror _class;

  Set<Symbol> _primaryKeys = Set();

  Map<String, Symbol> _nameToSymbol = {};
  Map<Symbol, String> _symbolToName = {};
  Map<Symbol, Field> _symbolToField = {};

  Iterable<String> get names => _nameToSymbol.keys;
  Iterable<Symbol> get symbols => _symbolToName.keys;

  String getName(Symbol symbol) => _symbolToName[symbol];
  Symbol getSymbol(String name) => _nameToSymbol[name];

  String getFieldName(field) {
    if (field is Symbol) return getName(field);
    return field.toString();
  }

  String getFullFieldName(field) {
    return '$name.${getFieldName(field)}';
  }

  String _name;
  String get name => _name;

  Symbol _symbol;
  Symbol get symbol => _symbol;

  String operator [](Symbol symbol) => getFullFieldName(symbol);

  Iterable<List> _getSymbolAndName(DeclarationMirror mirror) sync* {
    String name;
    Field field;
    var symbol = mirror.simpleName;
    var meta = mirror.metadata.firstWhere(
        (metaMirror) => metaMirror.reflectee is Field,
        orElse: () => null);
    if (meta != null) {
      field = meta.reflectee;
      name = field?.name;
    }
    name ??= MirrorSystem.getName(symbol);
    yield [symbol, name, field];
  }

  Model._(this._db, String name) {
    _class = reflectType(T) as ClassMirror;
    _symbol = _class.simpleName;
    _name = name ?? MirrorSystem.getName(_symbol);

    _class.declarations.values.forEach((decl) {
      if (decl is VariableMirror) {
        _getSymbolAndName(decl).forEach((list) {
          _nameToSymbol[list[1]] = list[0];
          _symbolToName[list[0]] = list[1];
          _symbolToField[list[0]] = list[2];
          if (list[2].primaryKey) _primaryKeys.add(list[0]);
        });
      }
    });
  }

  static Model<T> createModel<T>(Database db, String name) {
    return db.getModel<T>(name);
  }

  selectSql(SqlStmt condition, {int limit, int offset}) {
    var buf = StringBuffer();
    buf..write('select ')..write(names.join(','))..write(' from ')..write(name);
    if (condition != null) {
      buf..write(' where ')..write(condition.toSql(this));
    }
    if (limit != null) {
      buf.write(' limit $limit');
    }
    if (offset != null) {
      buf.write(' offset $offset');
    }
    return buf.toString();
  }

  countSql(SqlStmt condition) {
    var buf = StringBuffer();
    buf..write('select count(*) from ')..write(name);
    if (condition != null) {
      buf..write(' where ')..write(condition.toSql(this));
    }
    return buf.toString();
  }

  deleteSql(SqlStmt condition) {
    var buf = StringBuffer();
    buf..write('delete from ')..write(name);
    if (condition != null) {
      buf..write(' where ')..write(condition.toSql(this));
    }
    return buf.toString();
  }

  insertSql(T data) {
    var inst = reflect(data);
    var fields = [];
    var values = [];
    for (var entry in _nameToSymbol.entries) {
      fields.add(entry.key);
      values.add(SqlStmt.getValue(this, inst.getField(entry.value).reflectee));
    }
    var buf = StringBuffer();
    buf
      ..write('insert into ')
      ..write(name)
      ..write(' (${fields.join(',')}) ')
      ..write('values')
      ..write(' (${values.join(',')})');
    return buf.toString();
  }

  updateSql(T data, {List<Symbol> updateFields, SqlStmt condition}) {
    var inst = reflect(data);
    if (condition == null) {
      if (_primaryKeys.isEmpty) {
        throw 'There isn\'t a primary key.';
      } else {
        condition = And(_primaryKeys.map((symbol) {
          var value = inst.getField(symbol).reflectee;
          if (value == null) {
            throw 'Primary key can\'t be null in where clause.';
          }
          return Eq(_symbolToName[symbol], value);
        }));
      }
    }
    var setFields = [];
    Iterable<MapEntry<String, Symbol>> entries;
    if (updateFields != null) {
      var entrs = <String, Symbol>{};
      updateFields.forEach((symbol) {
        var name = _symbolToName[symbol];
        if (name != null) entrs[name] = symbol;
      });
      entries = entrs.entries;
    } else {
      entries = _nameToSymbol.entries;
    }
    for (var entry in entries) {
      var symbol = entry.value;
      var value = inst.getField(symbol).reflectee;
      if (value == null) {
        var field = _symbolToField[symbol];
        if (field != null && (field.primaryKey || field.notNull)) continue;
      }
      var setField = '${entry.key}=${SqlStmt.getValue(this, value)}';
      setFields.add(setField);
    }
    var buf = StringBuffer();
    buf
      ..write('update ')
      ..write(name)
      ..write(' set ')
      ..write(setFields.join(','))
      ..write(' where ')
      ..write(condition.toSql(this));

    return buf.toString();
  }

  dropTableSql() {
    return 'drop table if exists `$name`';
  }

  createTableSql() {
    List<String> defineFields = [];
    _nameToSymbol.forEach((name, symbol) {
      var decl = _class.declarations[symbol] as VariableMirror;

      String type;
      if (decl.type.isSubtypeOf(reflectType(String))) {
        type = 'varchar(255)';
      } else if (decl.type.isSubtypeOf(reflectType(int))) {
        type = 'int';
      } else if (decl.type.isSubtypeOf(reflectType(double))) {
        type = 'double';
      }
      if (type == null) return;

      String defineField = '`$name`';
      defineField += ' $type';

      var field = _symbolToField[symbol];
      if (field != null) {
        if (field.notNull || field.primaryKey) defineField += ' not null';
        if (field.autoIncrement) defineField += ' auto_increment';
      }
      defineFields.add(defineField);
    });

    var primaryKeys =
        _primaryKeys.map((symbol) => '`${_symbolToName[symbol]}`').join(',');

    var buf = StringBuffer();
    buf.write('create table if not exists ');
    buf.write('`$name` ');
    buf.write('(');
    buf.write(defineFields.join(', '));
    if (primaryKeys != null && primaryKeys.isNotEmpty) {
      buf.write(', primary key ($primaryKeys)');
    }
    buf.write(')');

    return buf.toString();
  }

  Future<Iterable<T>> select(SqlStmt condition, {int limit, int offset}) async {
    var result =
        await _db.query(selectSql(condition, limit: limit, offset: offset));

    return (() sync* {
      for (var row in result) {
        var inst = _class.newInstance(Symbol(''), []);
        for (var entry in _nameToSymbol.entries) {
          inst.setField(entry.value, row[entry.key]);
        }
        yield inst.reflectee as T;
      }
    })();
  }

  Future<T> selectOne(SqlStmt condition) async {
    var records = await select(condition, limit: 1);
    if (records.isEmpty) return null;
    return records.first;
  }

  Future<int> count(SqlStmt condition) async {
    var result = await _db.query(countSql(condition));
    return result.first[0];
  }

  Future delete(SqlStmt condition) async {
    return await _db.query(deleteSql(condition));
  }

  Future insert(T data) async {
    return await _db.query(insertSql(data));
  }

  Future update(T data, {List<Symbol> updateFields, SqlStmt condition}) async {
    return await _db.query(
        updateSql(data, updateFields: updateFields, condition: condition));
  }

  Future createTable({bool recreate = false}) async {
    if (recreate) await _db.query(dropTableSql());
    return await _db.query(createTableSql());
  }

  static bool unionTo<T>(T from, T to) {
    var changed = false;
    var fromInst = reflect(from), toInst = reflect(to);
    var type = reflectClass(T);
    type.declarations.values.forEach((mirror) {
      if (mirror is VariableMirror) {
        var name = mirror.simpleName;
        var value = fromInst.getField(name).reflectee;
        if (value != null && toInst.getField(name).reflectee == null) {
          toInst.setField(name, value);
          changed = true;
        }
      }
    });
    return changed;
  }

  static value<T>(T t, field) {
    var tInst = reflect(t);
    if (field is! Symbol) {
      field = MirrorSystem.getSymbol(field);
    }
    return tInst.getField(field).reflectee;
  }

  /// 导入xlsx
  /// fields: ['A', 'C']
  Future loadXlsx(
      {String xlsx,
      int startRow,
      int endRow,
      List<String> fields,
      List<String> notQuotes = const []}) async {
    var workbook = Workbook.fromFile(xlsx);
    var sheet = workbook.sheetAt(0);
    var buf = StringBuffer();

    for (var index = startRow; index <= endRow; index++) {
      var values = <String>[];
      for (var row in fields) {
        var value = sheet.rowAt(index).cell(row).value();
        if (!notQuotes.contains(row)) {
          value = "'$value'";
        }
        values.add(value);
      }
      buf.write(values.join(','));
      buf.write('\n');
    }

    var tmpfile = File(temporaryFilePath());
    try {
      tmpfile.writeAsStringSync(buf.toString());
      var loadSql =
          "load data infile '${tmpfile.path.replaceAll('\\', '\\\\')}' into table `$name` "
          "CHARACTER SET utf8 FIELDS TERMINATED BY ',' "
          "OPTIONALLY ENCLOSED BY '\\'' LINES TERMINATED BY '\\n'";
      return await _db.query(loadSql);
    } finally {
      tmpfile.deleteSync();
    }
  }
}

abstract class SqlStmt {
  String toSql(Model model);

  static String getValue(Model model, value) {
    if (value is String)
      return "'$value'";
    else if (value is SqlStmt) {
      return '(${value.toSql(model)})';
    } else {
      return value.toString();
    }
  }
}

abstract class SqlExpr extends SqlStmt {
  final dynamic field;
  final dynamic value;
  final String op;

  SqlExpr(this.op, this.field, this.value);

  String toSql(Model model) =>
      '${model.getFieldName(field)}$op${SqlStmt.getValue(model, value)}';
}

class Eq extends SqlExpr {
  Eq(field, value) : super('=', field, value);
}

class Ne extends SqlExpr {
  Ne(field, value) : super('<>', field, value);
}

class Gt extends SqlExpr {
  Gt(field, value) : super('>', field, value);
}

class Gte extends SqlExpr {
  Gte(field, value) : super('>=', field, value);
}

class Lt extends SqlExpr {
  Lt(field, value) : super('<', field, value);
}

class Lte extends SqlExpr {
  Lte(field, value) : super('<=', field, value);
}

class Is extends SqlExpr {
  Is(field, value) : super(' is ', field, value);
  Is.Not(field, value) : super(' is not ', field, value);
}

class In extends SqlExpr {
  In(field, value) : super(' in ', field, value);
  In.Not(field, value) : super(' not in ', field, value);
}

abstract class SqlRel extends SqlStmt {
  Iterable<SqlStmt> cmps;
  String op;

  SqlRel(this.op, this.cmps);

  String toSql(Model model) {
    return cmps.map((cmp) {
      var sql = cmp.toSql(model);
      if (cmp is SqlRel) sql = "($sql)";
      return sql;
    }).join(op);
  }
}

class And extends SqlRel {
  And(Iterable<SqlStmt> cmps) : super(' and ', cmps);
  And.Eq(field, List value) : this(value.map((v) => Eq(field, v)));
}

class Or extends SqlRel {
  Or(Iterable<SqlStmt> cmps) : super(' or ', cmps);
  Or.Eq(field, List value) : this(value.map((v) => Eq(field, v)));
}
