import 'package:yhcjb/yhqb.dart';
import 'package:commander/commander.dart';

main(List<String> args) {
  var program = Command()..setDescription('职保信息查询程序');

  program.command('info')
    ..setDescription('职保参保信息查询')
    ..setArguments('<idcard|name>', {'idcard|name': '身份证号码或姓名'})
    ..setAction((List args) => info(args[0]));

  program.parse(args);
}

info(String idOrName) {
  Session.use((session) {
    if (RegExp(r'^\d+X?$').hasMatch(idOrName)) {
      session.sendEnvelop(request: SncbrycxRequest(idcard: idOrName));
    } else {
      session.sendEnvelop(request: SncbrycxRequest(name: idOrName));
    }
    var response = session.getEnvelop<SncbrycxResponse>();

    if (response.body.count > 0) {
      var i = 1;
      for (var ry in response.body.list) {
        print('${i++}'.padLeft(4) +
          '. ' + '${ry.idcard}'.padRight(19) +
          '${ry.name} ${ry.sbjg} ${ry.cbzt} ${ry.jfrylx} ' +
          '${ry.shbxzt} ${ry.personID} ${ry.companyID}');
      }
    } else {
      print('未查到参保信息');
    }
  });
}
