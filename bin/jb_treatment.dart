import 'package:yhcjb/yhcjb.dart';
import 'package:xlsx_decoder/xlsx_decoder.dart' as xlsx;

main(List<String> args) {
  var runner = CommandRunner('jb_treatment', '信息核对报告表和养老金计算表生成程序')
    ..addCommand(new Fphd());

  runner.run(args);
}

class Fphd extends ArgumentsCommand {
  Fphd()
      : super('fphd',
            arguments: '<date>', description: '从业务系统下载生成到龄贫困人员待遇核定情况表');

  @override
  void execute(List<String> args) {
    print(args[0]);
  }
}
