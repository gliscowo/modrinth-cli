import 'package:args/src/arg_results.dart';

import '../modrinth.dart';
import '../util.dart';

class ProjectVersionsCommand extends ModrinthCommand {
  ProjectVersionsCommand()
      : super("project-versions",
            "Display versions of the specified project. If [version] is not specified, display the latest one",
            requiredArgCount: 1, argsDescription: "<project> [version]") {
    argParser.addOption("count", abbr: "c", help: "How many version to backtrack from the given one");
  }

  @override
  void execute(ArgResults args) async {
    final versions = await modrinth.projects.getVersions(args.rest[0]).then((value) => value?.toList());
    if (versions == null) {
      logger.warning("No project with id ${args.rest[0]} was found");
      return;
    }

    if (versions.isEmpty) {
      logger.warning("This project provided has no versions to display");
      return;
    }

    final targetVersionIndex = args.rest.length < 2
        ? args.rest.length - 1
        : versions.indexWhere((element) => element.versionNumber.contains(args.rest[1]));

    if (targetVersionIndex == -1) {
      logger.warning("No matching version was found");
      return;
    }

    final displayCount = args.wasParsed("count") ? int.parse(args["count"]) : 1;
    for (var i = 0; i < displayCount; i++) {
      printFormatted(versions[targetVersionIndex + i]);
    }
  }
}
