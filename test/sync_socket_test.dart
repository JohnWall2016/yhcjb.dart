import 'dart:io';
import 'package:yhcjb/src/net/sync_socket.dart';

void main(List<String> args) {
  var socket = SyncSocket('10.136.6.99', 7010);
  var body = socket.getHttp('/hncjb/pages/html/index.html');
  stdout.write(body);
}

