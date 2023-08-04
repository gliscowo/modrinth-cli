import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:console/console.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:modrinth_api/modrinth_api.dart' as mr;

import 'commands/changelog_command.dart';
import 'commands/inspect_command.dart';
import 'commands/install_command.dart';
import 'commands/project_command.dart';
import 'commands/search_command.dart';
import 'commands/upgrade_all_command.dart';
import 'commands/upgrade_command.dart';
import 'commands/version_command.dart';

const version = "0.0.5";
final modrinth = mr.ModrinthApi.createClient("gliscowo/modrinth-cli/$version");
final client = Client();
final logger = Logger("modrinth");

void main(List<String> arguments) async {
  Console.init();

  Logger.root.onRecord.listen((event) {
    final color = levelToColor(event.level);
    TextPen()
        .setColor(color)
        .text(event.level.name.toLowerCase())
        .white()
        .text(": ")
        .normal()
        .text(event.message)
        .print();
  });

  logger.info("modrinth cli v$version");

  final runner = CommandRunner<void>("modrinth", "A CLI wrapper for the Modrinth API");

  runner.argParser.addFlag("verbose", abbr: "v");

  runner.addCommand(InstallCommand());
  runner.addCommand(SearchCommand());
  runner.addCommand(ProjectCommand());
  runner.addCommand(VersionCommand());
  runner.addCommand(ProjectVersionsCommand());
  runner.addCommand(InspectCommand());
  runner.addCommand(UpgradeCommand());
  runner.addCommand(UpgradeAllCommand());

  try {
    final results = runner.parse(arguments);
    Logger.root.level = results.wasParsed("verbose") ? Level.FINE : Level.INFO;

    await runner.run(arguments);
  } on UsageException catch (usage) {
    print(usage);
  } on Error catch (e) {
    logger.severe("The following error occured while executing the command: $e");
    logger.fine("Stacktrace:\n${e.stackTrace}");
  } catch (thrown, stack) {
    logger.severe("Unknown error: $thrown");
    logger.fine("Stacktrace:\n$stack");
  }

  modrinth.dispose();
  client.close();
}

abstract class ModrinthCommand extends Command<void> {
  final String _name, _description, _argsDescription;
  final int _requiredArgCount;

  ModrinthCommand(this._name, this._description, {int requiredArgCount = 0, String? argsDescription})
      : _requiredArgCount = requiredArgCount,
        _argsDescription = argsDescription ?? "";

  @override
  FutureOr<void> run() {
    if (argResults!.rest.length < _requiredArgCount) {
      printUsage();
      return null;
    }
    return execute(argResults!);
  }

  @override
  String get invocation => super.invocation.replaceAll("[arguments]", _argsDescription);

  FutureOr<void> execute(ArgResults args);

  @override
  String get name => _name;
  @override
  String get description => _description;
}

Color levelToColor(Level level) {
  return switch (level.value) {
    > 900 => Color.RED,
    > 800 => Color.YELLOW,
    < 700 => Color.LIGHT_GRAY,
    _ => Color.WHITE
  };
}
