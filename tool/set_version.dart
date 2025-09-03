import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '_helpers.dart';

void main() async {
  final pubspecPath = path.join(projectRoot, 'pubspec.yaml');
  final pubspec = await File(pubspecPath).readAsString();
  final pck = loadYamlDocument(pubspec).contents as YamlMap;
  final version = (pck['version'] as String? ?? '').trim();

  if (version.isEmpty) {
    throw 'Missing version in pubspec.yaml.';
  } else if (RegExp('[\\t\\r\\n "\'\\\\]').hasMatch(version)) {
    throw 'Version contains illegal characters.';
  }

  final versionPath = path.join(projectRoot, 'lib', 'version.dart');
  final curSrc = await File(versionPath).readAsString();
  final src = '''
// GENERATED CODE - DO NOT MODIFY BY HAND
const version = '$version';
''';
  if (curSrc != src) {
    await File(versionPath).writeAsString(src);
    print('Set version to "$version".');
  } else {
    print('Version already set to "$version".');
  }
}
