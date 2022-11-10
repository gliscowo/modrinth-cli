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

    final mods = Directory.current.listSync().whereType<File>().where((element) => element.path.endsWith(".jar"));
    final upgradeFiles = await modrinth.latestFilesWithLoaderAndGameVersion(mods.toList(), loader, gameVersion);

    if (upgradeFiles == null) {
      logger.severe("Could not fetch updated versions from modrinth");
      return;
    }

    final upgrades = upgradeFiles
        .map((key, value) => MapEntry(key, primaryFileOf(value, chooseFirstAsDefault: true)))
        .entries
        .where((element) => basename(element.key.path) != element.value.filename)
        .map((e) => _UpgradeInfo(e.key, e.value));

    if (upgrades.isEmpty) {
      logger.info("${Color.GREEN}Everything up to date!");
      return;
    }

    print("");
    logger.info("${Color.GREEN}The following ${upgrades.length} mods can be updated:\n");

    final longest = (upgrades.map((e) => basename(e.oldFile.path).length).toList()..sort()).last;
    for (var upgrade in upgrades) {
      logger.info("${basename(upgrade.oldFile.path).padRight(longest)} -> ${upgrade.newFile.filename}");
    }

    if (!(Prompter("\n${Color.BLUE}Proceed? [y/n] ").askSync() ?? false)) return;

    await Future.wait(upgrades.map((e) => downloadFile(e.newFile).then((value) => e.oldFile.delete())));
  }
}

class _UpgradeInfo {
  final File oldFile;
  final ModrinthFile newFile;
  _UpgradeInfo(this.oldFile, this.newFile);
}
