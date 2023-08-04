import 'dart:io';

import 'package:console/console.dart';
import 'package:http/http.dart';
import 'package:modrinth_api/modrinth_api.dart';

import 'modrinth.dart';

final String keyColor = color(0xFCA17D);
const String valueColor = "${Console.ANSI_ESCAPE}0m";

void printFormatted(Object data, {bool prependNewline = true}) {
  final formattable = Formattable(data);
  if (prependNewline) print("");

  for (var entry in formattable.formatted.entries) {
    print("$keyColor${entry.key}: $valueColor${entry.value}");
  }
}

extension PrimaryFile on ModrinthVersion {
  ModrinthFile primaryFile({bool chooseFirstAsDefault = false}) {
    logger.fine("Files: $files");

    final latestFile = files.firstWhere((v) => v.primary, orElse: () {
      if (chooseFirstAsDefault) return files[0];

      logger.warning("The specified version has no primary file");
      return Chooser(
        files,
        message: "Choose file to download: ",
        formatter: (file, idx) => "${Color.LIGHT_CYAN}($idx) ${Color.WHITE}${(file).filename}",
      ).chooseSync();
    });

    return latestFile;
  }
}

Future<void> downloadFile(ModrinthFile file) async {
  logger.info("Downloading file ${file.filename}");

  await client
      .send(Request("GET", Uri.parse(file.url)))
      .then((value) => value.stream.pipe(File(file.filename).openWrite()));

  logger.info("Success!");
}

String color(int rgb) => "${Console.ANSI_ESCAPE}38;2;${rgb >> 16};${(rgb >> 8) & 0xFF};${rgb & 0xFF}m";

abstract class Formattable {
  Map<String, String> get formatted;

  factory Formattable(final Object data) {
    if (data is Formattable) {
      return data;
    } else if (data is ModrinthSearchResult) {
      return _FormattableSearchResult(data);
    } else if (data is ModrinthVersion) {
      return _FormattableVersion(data);
    }

    throw ArgumentError.value(data, "data", "No formattable wrapper avaiable");
  }
}

class _FormattableSearchResult implements Formattable {
  final ModrinthSearchResult _result;
  _FormattableSearchResult(this._result);

  @override
  Map<String, String> get formatted => {
        "Project": "${_result.title} (${_result.slug}, ${_result.projectId})",
        "Author": _result.author,
        "Downloads": _result.downloads.toString(),
        "Latest Minecraft Version": _result.latestVersion ?? "Not declared"
      };
}

class _FormattableVersion implements Formattable {
  final ModrinthVersion _version;
  _FormattableVersion(this._version);

  @override
  Map<String, String> get formatted => {
        "Version Name": _version.name,
        "Version Number": "${_version.versionNumber} (${_version.id})",
        "Downloads": _version.downloads.toString(),
        "Changelog": _version.changelog!.contains("\n") ? "\n${_version.changelog!}" : _version.changelog!
      };
}
