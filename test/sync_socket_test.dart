import 'dart:io';
import 'package:yhcjb/src/net/sync_socket.dart';

main() {
  var socket = SyncSocket('10.136.6.99', 7010);
  var body = socket.getHttp('/hncjb/pages/html/index.html');
  stdout.write(body);
}