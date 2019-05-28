import 'package:yhcjb/src/net/session.dart';

main() {
  /*print(GrinfoQuery('430311195702091516').toJson());

  Session.use((s) {
    s.sendService(GrinfoQuery('430311195702091516'));
    var result = s.getResult<Grinfo>();
    print(result[0].name);
    print(result[0].idcard);
    print(result[0].toJson());
  });*/

  /*print(DyryQuery(dlny: '2019-04-30').toJson());
  Session.use((s) {
    s.sendService(DyryQuery(dlny: '2019-04-30'));
    print(s.readHttpBody());
  });*/

  Session.use((s) {
    s.sendService(DyfhQuery(shzt: '1', qsshsj: '2019-05-15'));
    //print(s.readHttpBody());
    var result = s.getResult<Dyfh>();
    if (result.isNotEmpty) {
      print(result[0].toJson());
      var pinfo = result[0].paymentInfo;
      print(pinfo[1]);
      print(pinfo[2]);
    }
  });
}
