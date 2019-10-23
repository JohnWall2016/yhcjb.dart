import 'package:yhcjb/yhqb.dart';

main() {
  Session.use((session) {
    print(session.loginInfo.header.username);
    print(session.loginInfo.body.operatorName);
    for (var acl in session.loginInfo.body.acl) {
      print(acl.id);
    }
  });
}