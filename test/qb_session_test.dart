import 'package:yhcjb/yhqb.dart';

main() {
  Session.use((session) {
    /*
    print(session.loginInfo.header.username);
    print(session.loginInfo.body.operatorName);
    for (var acl in session.loginInfo.body.acl) {
      print(acl.id);
    }
    */
    // session.sendEnvelop(request: SncbrycxRequest('43030219'));
    // session.sendEnvelop(request: SncbrycxRequest(idcard: '43031119'));
    session.sendEnvelop(request: SncbrycxRequest(name: '李', idcard: '43031119'));
    // print(session.readHttpBody());
    var response = session.getEnvelop<SncbrycxResponse>();
    
    if (response.body.count > 0) {
      var i = 1;  
      for (var sncbry in response.body.list) {
        //print(sncbry);
        print('${i++}: ${sncbry.toJson(true)}');
      }
    }
  });
}