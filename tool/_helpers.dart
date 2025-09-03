import 'dart:io';

import 'package:path/path.dart' as path;

final projectRoot = findRootOfProject();

List<String> overrideDefaultArgs(
    List<String> args, String def, Iterable<String> defaultArgs) {
  args = args.toList(); // make args a modifiable list
  if (args.isEmpty || args.contains(def)) {
    args.remove(def);
    for (var arg in defaultArgs) {
      if (!args.contains(arg)) args.add(arg);
    }
  }
  return args;
}

bool takeArg(List<String> args, String arg) {
  if (args.contains(arg)) {
    args.removeWhere((a) => a == arg);
    return true;
  } else {
    return false;
  }
}

void reportUnknownArgs(List<String> args) {
  if (args.isNotEmpty) {
    print('Unknown arguments: ${args.join(', ')}');
  }
}

String findRootOfProject() {
  var dir = Directory.current.absolute;
  while (dir
      .listSync()
      .where((f) => f is File && f.baseName == 'pubspec.yaml')
      .isEmpty) {
    if (dir == dir.parent) {
      throw Exception(
          'The tool must be run from the root or a subdirectory of your project.');
    }
    dir = dir.parent;
  }
  return dir.absolute.path;
}

extension FileSystemEntityExt on FileSystemEntity {
  String get baseName => path.basename(this.path);

  String get projectPath {
    final abs = absolute.path;
    return abs.startsWith(projectRoot)
        ? abs.substring(projectRoot.length + 1)
        : abs;
  }
}
