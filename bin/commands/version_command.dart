import 'dart:async';

import 'package:args/src/arg_results.dart';

import '../modrinth.dart';
import '../util.dart';

class VersionCommand extends ModrinthCommand {
  VersionCommand() : super("version", "Show information about a specific version", requiredArgCount: 1);

  @override
  FutureOr<void> execute(ArgResults args) async {
    var version = await modrinth.versions.get(args.rest[0]);
    if (version == null) {
      logger.warning("No version with id ${args.rest[0]} was found");
      return;
    }

    printFormatted(version);
  }
}
