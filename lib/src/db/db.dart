import 'package:mysql1/mysql1.dart';
export 'package:mysql1/mysql1.dart';

import './_config.dart';

Future<MySqlConnection> getDbConnection() async {
  final conn = await MySqlConnection.connect(new ConnectionSettings(
      host: conf['host'], port: conf['port'], user: conf['user'], password: conf['password'], db: conf['db']));
  return conn;
}
