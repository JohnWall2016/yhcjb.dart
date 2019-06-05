import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:math';

stop(String message, [int code = -1]) {
  print(message);
  exit(code);
}

List<String> getYearMonthDay(date) {
  var ma = RegExp(r'^(\d\d\d\d)(\d\d)(\d\d)$').firstMatch(date);
  if (ma != null) {
    var y = ma.group(1);
    var m = ma.group(2);
    var d = ma.group(3);
    var ymd = '$y-$m-$d';

    if (m[0] == '0') m = m.substring(1);
    if (d[0] == '0') d = d.substring(1);

    return [y, m, d, ymd];
  } else {
    throw ArgumentError('Invalid date format (YYYYMMDD).');
  }
}

String tmpDir() {
  String path;

  if (Platform.isWindows) {
    path = Platform.environment['SystemRoot'] ?? Platform.environment['windir'];
    return Platform.environment['TEMP'] ??
        Platform.environment['TMP'] ??
        p.join(path, 'temp');
  } else {
    return Platform.environment['TMPDIR'] ??
        Platform.environment['TMP'] ??
        Platform.environment['TEMP'] ??
        '/tmp';
  }
}

const _randomChars =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

String randomString(int length) {
  StringBuffer buf = StringBuffer();
  var rnd = Random();
  var max = _randomChars.length;

  for (var i = 0; i < length; i++) {
    buf.write(_randomChars[rnd.nextInt(max)]);
  }
  return buf.toString();
}

String tmpName([String prefix, String postfix]) {
  prefix ??= 'tmp-';
  postfix ??= '';

  return prefix + randomString(12) + postfix;
}

String temporaryFilePath([String prefix, String postfix]) =>
    p.join(tmpDir(), tmpName());

String getFormatDate() {
  var d = DateTime.now();
  return '${d.year}' +
      '${d.month}'.padLeft(2, '0') +
      '${d.day}'.padLeft(2, '0');
}
