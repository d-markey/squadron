import 'dart:io';

import 'package:path/path.dart' as path;

import '_helpers.dart';

final projectRoot = findRootOfProject();

void main(List<String> args) async {
  args = overrideDefaultArgs(args, 'all', ['runners', 'js', 'wasm']);

  final test = path.join(projectRoot, 'test');
  final futures = <Future<void>>[];

  if (takeArg(args, 'runners')) {
    final browserTests = Directory(path.join(test, 'browser-tests'));
    print('Clean up browser test runners from ${browserTests.projectPath}...');
    futures.addAll(_clean(browserTests, _jsExts).toList());
    futures.addAll(_clean(browserTests, _wasmExts).toList());
  }

  if (takeArg(args, 'js')) {
    final jsWorkers = Directory(path.join(test, 'workers', 'js'));
    print('Clean up JavaScript workers from ${jsWorkers.projectPath}...');
    futures.addAll(_clean(jsWorkers, _jsExts).toList());
  }

  if (takeArg(args, 'wasm')) {
    final wasmWorkers = Directory(path.join(test, 'workers', 'wasm'));
    print('Clean up Web Assembly workers from ${wasmWorkers.projectPath}...');
    futures.addAll(_clean(wasmWorkers, _wasmExts).toList());
  }

  reportUnknownArgs(args);

  await Future.wait(futures);

  print('Done.');
}

final _wasmExts = [
  RegExp(r'.*\.dart\.mjs$'),
  RegExp(r'.*\.dart\.wasm$'),
  RegExp(r'.*\.dart\.wasm\.map$'),
  RegExp(r'.*\.dart\.unopt\.wasm$'),
  RegExp(r'.*\.dart\.unopt\.wasm\.map$'),
];
final _jsExts = [
  RegExp(r'.*\.dart\.js$'),
  RegExp(r'.*\.dart\.js\.deps$'),
  RegExp(r'.*\.dart\.js\.map$'),
];

Iterable<Future<void>> _clean(
    Directory directory, Iterable<Pattern> patterns) sync* {
  final files = directory
      .listSync()
      .where((f) => patterns.any((p) => p.allMatches(f.path).isNotEmpty));
  for (var f in files) {
    yield f
        .delete()
        .then(
          (_) => '* Deleted ${f.projectPath}',
          onError: (ex, st) => '[${f.projectPath}] ${ex.runtimeType}: $ex\n$st',
        )
        .then(print);
  }
}