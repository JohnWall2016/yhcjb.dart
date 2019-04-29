import 'package:yhcjb/src/json/json.dart';
import 'package:yhcjb/src/net/session.dart';

main() {
  var serv = Service(
      id: 'executeSncbxxConQ',
      params: SncbxxConQ()..idcard = '430302197502023052',
      userId: '430302002',
      password: '72fb9d9c611b751ddeaefdedda7a557b');
  print(serv.toJson());
}

class SncbxxConQ extends Jsonable {
  @Json(name: 'aac002')
  String idcard;
}
