import 'package:yhcjb/src/net/session.dart';

main() {
  print(GrinfoQuery('430311195702091516').toJson());

  Session.use((s) {
    s.sendService(GrinfoQuery('430311195702091516'));
    var result = s.getResult<Grinfo>();
    print(result[0].name);
    print(result[0].idcard);
    print(result[0].toJson());
  });
}
