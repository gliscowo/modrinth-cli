import 'dart:async';
import 'dart:io';

import 'package:args/src/arg_results.dart';
import 'package:path/path.dart';

import '../modrinth.dart';
import '../util.dart';

class UpgradeCommand extends ModrinthCommand {
  UpgradeCommand()
      : super(
          "upgrade",
          "Upgrade the given mod file to its latest version for the given game version and modloader",
          requiredArgCount: 2,
          argsDescription: "<file> <game version> <loader>",
        );

  @override
  FutureOr<void> execute(ArgResults args) async {
    final filePath = args.rest[0];
    final gameVersion = args.rest[1];
    final loader = args.rest.length < 3 ? "fabric" : args.rest[2];

    var oldFile = File(filePath);

    var newVersion = await modrinth.versionFiles.getLatestVersionFromFile(
      oldFile,
      loaders: [loader],
      gameVersions: [gameVersion],
    );

    if (newVersion == null) {
      logger.warning("No version found");
      return;
    }

    final primaryFile = newVersion.primaryFile();
    if (primaryFile.filename == basename(oldFile.path)) {
      logger.info("Already on latest version");
    } else {
      await downloadFile(primaryFile);
      oldFile.deleteSync();
    }
  }
}
