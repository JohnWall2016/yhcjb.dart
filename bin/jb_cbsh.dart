import 'package:yhcjb/yhcjb.dart';
import 'package:mysql1/mysql1.dart';

main(List<String> args) async {
  String qsshsj = args[0]; // '2019-04-29';
  print(qsshsj);

  Result<Cbsh> result;
  Session.use((session) {
    session.sendService(CbshQuery(qsshsj: qsshsj, shzt: '1'));
    result = session.getResult<Cbsh>();
  });

  if (result.length > 0) {   
    for (Cbsh cbsh in result?.datas) {
      print('${cbsh.idcard} ${cbsh.name} ${cbsh.birthday}');

    }
  }
}
