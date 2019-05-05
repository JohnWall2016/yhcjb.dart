import 'dart:mirrors';
import 'dart:collection';

import 'package:mysql1/mysql1.dart';
export 'package:mysql1/mysql1.dart';

import './_config.dart';

Future<MySqlConnection> getDbConnection() async {
  final conn = await MySqlConnection.connect(new ConnectionSettings(
      host: conf['host'],
      port: conf['port'],
      user: conf['user'],
      password: conf['password'],
      db: conf['db']));
  return conn;
}

class Entity {
  final String name;
  const Entity(this.name);
}

class Table extends Entity {
  const Table({String name}) : super(name);
}

class Field extends Entity {
  final bool primaryKey;
  const Field({String name, this.primaryKey = false}) : super(name);
}

@Table(name: '2019年度扶贫办民政残联历史数据')
class FpHistoryData {
  @Field(name: '序号')
  int no;

  @Field(name: '乡镇街')
  String xzj;

  @Field(name: '村社区')
  String csq;

  @Field(name: '地址')
  String address;

  @Field(name: '姓名')
  String name;

  @Field(name: '身份证号码', primaryKey: true)
  String idcard;

  @Field(name: '出生日期')
  String birthDay;

  @Field(name: '人员类型')
  String type;

  @Field(name: '类型细节')
  String detail;

  @Field(name: '数据月份')
  String date;
}

class Model<T> {
  MySqlConnection _db;
  ClassMirror _class;

  Set<Symbol> _primaryKeys = Set();

  Map<String, Symbol> _nameToSymbol = {};
  Map<Symbol, String> _symbolToName = {};

  Iterable<String> get names => _nameToSymbol.keys;
  Iterable<Symbol> get symbols => _symbolToName.keys;

  String getName(Symbol symbol) => _symbolToName[symbol];
  Symbol getSymbol(String name) => _nameToSymbol[name];

  String getFieldName(field) {
    if (field is Symbol) return getName(field);
    return field.toString();
  }

  String _name;
  String get name => _name;
  Symbol _symbol;
  Symbol get symbol => _symbol;

  Iterable<List> _getSymbolAndName<E extends Entity>(
      DeclarationMirror mirror) sync* {
    String name;
    bool primaryKey = false;
    var symbol = mirror.simpleName;
    var meta = mirror.metadata.firstWhere(
        (metaMirror) => metaMirror.reflectee is E,
        orElse: () => null);
    if (meta != null) {
      E entity = meta.reflectee;
      name = entity.name;
      if (entity is Field) {
        primaryKey = entity.primaryKey;
      }
    }
    name ??= MirrorSystem.getName(symbol);
    yield [symbol, name, primaryKey];
  }

  Model(this._db) {
    _class = reflectType(T) as ClassMirror;
    var iter = _getSymbolAndName<Table>(_class);
    if (iter.isNotEmpty) {
      var symname = iter.first;
      _symbol = symname[0];
      _name = symname[1];
    }
    _class.declarations.values.forEach((decl) {
      if (decl is VariableMirror) {
        _getSymbolAndName<Field>(decl).forEach((list) {
          _nameToSymbol[list[1]] = list[0];
          _symbolToName[list[0]] = list[1];
          if (list[2]) {
            _primaryKeys.add(list[0]);
          }
        });
      }
    });
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

  updateSql(T data, {SqlStmt condition}) {
    var inst = reflect(data);
    if (condition == null) {
      if (_primaryKeys.isEmpty) {
        throw 'There isn\'t a primary key.';
      } else {
        condition = And(_primaryKeys.map((symbol) =>
            Eq(_symbolToName[symbol], inst.getField(symbol).reflectee)));
      }
    }
    var setFields = [];
    for (var entry in _nameToSymbol.entries) {
      var setField =
          '${entry.key}=${SqlStmt.getValue(this, inst.getField(entry.value).reflectee)}';
      setFields.add(setField);
    }
    var buf = StringBuffer();
    buf
      ..write('update ')
      ..write(name)
      ..write(' set ')
      ..write(setFields.join(','));
    if (condition != null) {
      buf..write(' where ')..write(condition.toSql(this));
    }
    return buf.toString();
  }

  Stream<T> select(SqlStmt condition, {int limit, int offset}) async* {
    var result =
        await _db.query(selectSql(condition, limit: limit, offset: offset));
    for (var row in result) {
      var inst = _class.newInstance(Symbol(''), []);
      for (var entry in _nameToSymbol.entries) {
        inst.setField(entry.value, row[entry.key]);
      }
      yield inst.reflectee as T;
    }
  }

  Future delete(SqlStmt condition) async {
    return await _db.query(deleteSql(condition));
  }

  Future insert(T data) async {
    return await _db.query(insertSql(data));
  }

  Future update(T data, {SqlStmt condition}) async {
    return await _db.query(updateSql(data, condition: condition));
  }
}

abstract class SqlStmt {
  String toSql(Model model);

  static String getValue(Model model, value) {
    if (value is String)
      return "'$value'";
    else if (value is SqlStmt)
      return '(${value.toSql(model)})';
    else
      return value.toString();
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
