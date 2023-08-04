import 'dart:async';
import 'dart:convert';

import 'package:args/src/arg_results.dart';

import '../modrinth.dart';

final _encoder = JsonEncoder.withIndent("    ");

class InspectCommand extends ModrinthCommand {
  InspectCommand() : super("inspect", "Show technical information about a project or version") {
    addSubcommand(InspectProjectCommand());
    addSubcommand(InspectVersionCommand());
    addSubcommand(InspectUserCommand());
  }

  @override
  FutureOr<void> execute(ArgResults args) => throw StateError("Non-leaf command must not be called");
}

class InspectProjectCommand extends ModrinthCommand {
  InspectProjectCommand() : super("project", "Inspect a project", requiredArgCount: 1, argsDescription: "<project>") {
    argParser.addFlag("complete", abbr: "c", negatable: false, help: "Do not remove the 'body' and 'versions' fields");
  }

  @override
  FutureOr<void> execute(ArgResults args) async {
    final project = await modrinth.projects.get(args.rest[0]);
    if (project == null) {
      logger.warning("No project with id ${args.rest[0]} was found");
      return;
    }

    final projectData = project.toJson();
    if (!args.wasParsed("complete")) {
      projectData.remove("versions");
      projectData.remove("body");
    }
    print(_encoder.convert(projectData));
  }
}

class InspectUserCommand extends ModrinthCommand {
  InspectUserCommand() : super("user", "Inspect a user", requiredArgCount: 1, argsDescription: "<user>");

  @override
  FutureOr<void> execute(ArgResults args) async {
    final user = await modrinth.users.get(args.rest[0]);
    if (user == null) {
      logger.warning("No user with id ${args.rest[0]} was found");
      return;
    }

    print(user);
  }
}

class InspectVersionCommand extends ModrinthCommand {
  InspectVersionCommand() : super("version", "Inspect a version", requiredArgCount: 1, argsDescription: "<version id>");

  @override
  FutureOr<void> execute(ArgResults args) async {
    final version = await modrinth.versions.get(args.rest[0]);
    if (version == null) {
      logger.warning("No version with id ${args.rest[0]} was found");
      return;
    }

    print(version);
  }
}
