import 'package:mysql1/mysql1.dart';
export 'package:mysql1/mysql1.dart';

Future<MySqlConnection> getDbConnection() async {
  final conn = await MySqlConnection.connect(new ConnectionSettings(
      host: 'localhost', port: 3306, user: 'root', db: 'testdb'));
  return conn;
}
