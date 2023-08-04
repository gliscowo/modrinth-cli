import 'dart:async';

import 'package:args/src/arg_results.dart';

import '../modrinth.dart';
import '../util.dart';

class SearchCommand extends ModrinthCommand {
  SearchCommand()
      : super("search", "Search the given term on modrinth and print results",
            requiredArgCount: 1, argsDescription: "<search term(s)>");

  @override
  FutureOr<void> execute(ArgResults args) async {
    var searchTerm = args.rest.join(" ");
    logger.info("searching '$searchTerm'");

    var response = await modrinth.search(query: searchTerm);
    logger.info("${response.totalHits} results found");

    for (var hit in response.hits) {
      printFormatted(hit);
    }
  }
}
