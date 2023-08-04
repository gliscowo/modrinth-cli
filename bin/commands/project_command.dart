import 'dart:async';

import 'package:args/src/arg_results.dart';

import '../modrinth.dart';

class ProjectCommand extends ModrinthCommand {
  ProjectCommand() : super("project", "View information on the given project", requiredArgCount: 1) {
    argParser.addFlag("versions", abbr: "v", negatable: false, help: "List the project's versions");
    argParser.addFlag("latest", abbr: "l", negatable: false, help: "Show the project's latest version");
    argParser.addOption("get-property", abbr: "p", help: "Gets the given property of the project");
  }

  @override
  FutureOr<void> execute(ArgResults args) async {
    var projectId = args.rest[0];

    if (args.wasParsed("get-property")) {
      print((await modrinth.projects.get(projectId))!.toJson()[args["get-property"]]);
    } else if (args.wasParsed("latest")) {
      print((await modrinth.projects.getVersions(projectId))!.first);
    } else if (args.wasParsed("versions")) {
      print(await modrinth.projects.getVersions(projectId));
    } else {
      print(await modrinth.projects.get(projectId));
    }
  }
}
