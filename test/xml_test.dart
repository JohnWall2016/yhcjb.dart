import 'package:yhcjb/yhqb.dart';

main() {
  var en = Envelop(Sncbrycx('430302195806251012'));
  print(en.toXmlString());
}