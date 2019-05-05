import 'package:args/command_runner.dart';
export 'package:args/command_runner.dart';

class ArgumentsCommand extends Command {
  
  final String description;
  final String name;
  final String arguments;

  ArgumentsCommand(this.name, {this.description = '', this.arguments = ''});

  @override
  String get invocation {
    var parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner.executableName);

    var invocation = parents.reversed.join(" ");
    return subcommands.isNotEmpty
        ? "$invocation <subcommand> $arguments"
        : "$invocation $arguments";
  }

  void run() {
    var params = arguments.trim().split(RegExp(r'[ \t]+')).length;
    var args = argResults.rest.length;
    if (params > args) {
      print('Error: Too many arguments: $params expected, but $args got.\n');
      print(usage);
      return;
    }
    execute(argResults.rest);
  }

  void execute(List<String> arguments) {
    throw UnimplementedError();
  }

}