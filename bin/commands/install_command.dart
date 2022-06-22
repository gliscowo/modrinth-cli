import 'dart:async';

import 'package:args/src/arg_results.dart';
import 'package:modrinth_api/modrinth_api.dart';

import '../modrinth.dart';
import '../util.dart';

class InstallCommand extends ModrinthCommand {
  InstallCommand()
      : super("install", "Download the latest or specified version of the given mod to the current folder",
            requiredArgCount: 1, argsDescription: "<project> [version]") {
    argParser.addOption("game-version", help: "The game version for which to filter");
  }

  @override
  FutureOr<void> execute(ArgResults args) async {
    if (args.rest.isEmpty) {
      printUsage();
      return;
    }

    final versions = await modrinth.getProjectVersions(args.rest[0]);
    if (versions == null) {
      logger.warning("No project with id ${args.rest[0]} was found");
      return;
    }

    if (versions.isEmpty) {
      logger.warning("This project provided has no versions to download");
      return;
    }

    logger.fine("Versions: $versions");

    Iterable<ModrinthVersion> applicableVersions = versions;

    if (args.wasParsed("game-version")) {
      applicableVersions = applicableVersions.where((element) => element.gameVersions.contains(args["game-version"]));
    }

    if (args.rest.length > 1) {
      applicableVersions = applicableVersions.where((element) => element.versionNumber == args.rest[1]);
    }

    if (applicableVersions.isEmpty) {
      logger.warning("No matching version was found");
      return;
    }

    await downloadFile(primaryFileOf(applicableVersions.first));
  }
}
