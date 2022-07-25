import 'dart:async';
import 'dart:io';

import 'package:args/src/arg_results.dart';
import 'package:console/console.dart';
import 'package:modrinth_api/modrinth_api.dart';
import 'package:path/path.dart';

import '../modrinth.dart';
import '../util.dart';

class UpgradeAllCommand extends ModrinthCommand {
  UpgradeAllCommand()
      : super("upgrade-all",
            "Upgrade all mod files in the current directory to their latest version for the given game version and modloader",
            requiredArgCount: 1, argsDescription: "<game version> <loader>");

  @override
  FutureOr<void> execute(ArgResults args) async {
    final gameVersion = args.rest[0];
    final loader = args.rest.length < 2 ? "fabric" : args.rest[1];

    final upgrades = <_UpgradeInfo>[];
    final mods = Directory.current.listSync().whereType<File>().where((element) => element.path.endsWith(".jar"));

    for (final oldFile in mods) {
      logger.info("Processing ${basename(oldFile.path)}");

      var newVersion = await modrinth.latestWithLoaderAndGameVersion(oldFile, loader, gameVersion);
      Console.moveCursorUp();
      Console.eraseLine();

      if (newVersion == null) {
        logger.warning("No modrinth project for file ${basename(oldFile.path)} found, skipping");
        continue;
      }

      final primaryFile = primaryFileOf(newVersion, chooseFirstAsDefault: true);
      if (primaryFile.filename != basename(oldFile.path)) {
        logger.info("Found new version: ${Color.GREEN}${primaryFile.filename}");
        upgrades.add(_UpgradeInfo(oldFile, primaryFile));
      }
    }

    print("");
    logger.info("${Color.GREEN}The following ${upgrades.length} mods can be updated:\n");

    final longest = (upgrades.map((e) => basename(e.oldFile.path).length).toList()..sort()).last;
    for (var upgrade in upgrades) {
      logger.info("${basename(upgrade.oldFile.path).padRight(longest)} -> ${upgrade.newFile.filename}");
    }

    if (!(Prompter("\n${Color.BLUE}Proceed? [y/n] ").askSync() ?? false)) return;

    await Future.wait(upgrades.map((e) => downloadFile(e.newFile)));
  }
}

class _UpgradeInfo {
  final File oldFile;
  final ModrinthFile newFile;
  _UpgradeInfo(this.oldFile, this.newFile);
}
