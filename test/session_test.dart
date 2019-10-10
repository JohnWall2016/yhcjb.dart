import 'package:yhcjb/yhcjb.dart';

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

  /*Session.use((s) {
    s.sendService(DyfhQuery(shzt: '1', qsshsj: '2019-05-15'));
    //print(s.readHttpBody());
    var result = s.getResult<Dyfh>();
    if (result.isNotEmpty) {
      print(result[0].toJson());
      var pinfo = result[0].paymentInfo;
      print(pinfo[1]);
      print(pinfo[2]);
    }
  });*/
/*
  Session.use((s) {
    //print(CwzfglQuery('201905', '1'));
    //s.sendService(CwzfglQuery('201905', '1'));
    //print(s.readHttpBody());
    /*s.sendService(PausePaymentQuery('430302191912225020'));
    //print(s.readHttpBody());
    var result = s.getResult<PausePayment>();
    var pause = result.datas[0];
    print([pause.idcard, pause.name, pause.reasonChn, pause.time]);*/
    s.sendService(SuspiciousDeathQuery('360312193511161015'));
    print(s.readHttpBody());
  });
  */
  // print(padZero(10, 10));
  Session.use((s) {
    s.sendService(SncbqkcxjfxxQuery('430122195709247411'));//'430303195909191071'));
    //print(s.readHttpBody());
    var result = s.getResult<Sncbqkcxjfxx>();
    for (var data in result.datas) {
      /*print(data.memo);
      print(data.type);
      print(data.item);
      print(data.amount);*/
      //print(data);
      print(data.toJson(true));
    }
  });
}
