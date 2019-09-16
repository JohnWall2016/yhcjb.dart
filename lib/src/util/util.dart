import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:math' as math;
import 'package:decimal/decimal.dart';

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

List<String> getYearMonth(yearMonth) {
  var ma = RegExp(r'^(\d\d\d\d)(\d\d)$').firstMatch(yearMonth);
  if (ma != null) {
    var y = ma.group(1);
    var m = ma.group(2);

    if (m[0] == '0') m = m.substring(1);

    return [y, m];
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
  var rnd = math.Random();
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

const _bign = [
  '零',
  '壹',
  '贰',
  '叁',
  '肆',
  '伍',
  '陆',
  '柒',
  '捌',
  '玖',
];

const _place = ['', '拾', '佰', '仟', '万', '亿'];

const _unit = [
  '元',
  '角',
  '分',
];

const _whole = '整';

String getMoneyCh(Decimal number) {
  var n = (number * Decimal.fromInt(100)).toInt();
  var integer = n ~/ 100;
  var fraction = n % 100;

  int length = integer.toString().length;
  var ret = '';
  var zero = false;
  for (var i = length; i >= 0; i--) {
    var base = math.pow(10, i);
    if (integer ~/ base > 0) {
      if (zero) {
        ret += _bign[0];
      }
      ret += _bign[integer ~/ base] + _place[i % 4];
      zero = false;
    } else if (integer ~/ base == 0 && ret != '') {
      zero = true;
    }
    if (i >= 4) {
      if (i % 8 == 0 && ret != '') {
        ret += _place[5];
      } else if (i % 4 == 0 && ret != '') {
        ret += _place[4];
      }
    }
    integer = integer % base;
    if (integer == 0 && i != 0) {
      zero = true;
      break;
    }
  }
  ret += _unit[0];

  if (fraction == 0) {
    // .00
    ret += _whole;
  } else if (fraction % 10 == 0) {
    // .D0
    if (zero) {
      ret += _bign[0];
    }
    ret += _bign[fraction ~/ 10] + _unit[1] + _whole;
  } else {
    // .0D or .DD
    if (zero || fraction ~/ 10 == 0) {
      ret += _bign[0];
    }
    if (fraction ~/ 10 != 0) {
      // .DD
      ret += _bign[fraction ~/ 10] + _unit[1];
    }
    ret += _bign[fraction % 10] + _unit[2];
  }
  return ret;
}

String appendToFileName(String fileName, String appendString) {
  var index = fileName.lastIndexOf('.');
  if (index >= 0) {
    return fileName.substring(0, index) +
        appendString +
        fileName.substring(index);
  } else {
    return fileName + appendString;
  }
}

String padZero(int num, [digit = 2]) {
  var pad = StringBuffer();
  while (--digit > 0) {
    var limit = math.pow(10, digit);
    if (num >= limit) {
      break;    
    } else {
      pad.write('0');
    }
  }
  pad.write(num);
  return pad.toString();
}

int previousMonth(int yearMonth) {
  var y = yearMonth ~/ 100;
  var m = yearMonth % 100;
  m -= 1;
  if (m == 0) {
    m = 12;
    y -= 1;
  }
  return y * 100 + m;
}

int substractMonth(int firstYearMonth, int secondYearMonth) {
  var firstMonths = (firstYearMonth ~/ 100) * 12 + firstYearMonth % 100;
  var secondMonths = (secondYearMonth ~/ 100) * 12 + secondYearMonth % 100;
  return firstMonths - secondMonths;
}
