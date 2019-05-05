
getYearMonthDay(date) {
  var ma = RegExp(r'^(\d\d\d\d)(\d\d)(\d\d)$').firstMatch(date);
  if (ma != null) {
    var y = ma.group(1);
    var m = ma.group(2);
    var d = ma.group(3);
    var ymd = '$y-$m-$d';

    if (m[0] == '0') m = m.substring(1);
    if (d[0] == '0') d = d.substring(1);

    return [
      y, m, d, ymd
    ];
  } else {
    throw ArgumentError('Invalid date format (YYYYMMDD).');
  }
}