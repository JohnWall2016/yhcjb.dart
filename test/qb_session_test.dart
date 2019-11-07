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
    session.sendEnvelop(request: SncbrycxRequest('430302195910141016'));
    //print(session.readHttpBody());
    var response = session.getEnvelop<SncbrycxResponse>();
    for (var sncbry in response.body.querylist) {
      //print(sncbry);
      print(sncbry.toJson(true));
    }
  });
}