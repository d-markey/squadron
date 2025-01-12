import 'dart:io';

import 'package:path/path.dart' as path;

import '_helpers.dart';

final projectRoot = findRootOfProject();

void main(List<String> args) async {
  args = overrideDefaultArgs(args, 'all', ['runners', 'js', 'wasm']);

  final testRoot = path.join(projectRoot, 'test');
  final futures = <Future<void>>[];

  if (takeArg(args, 'runners')) {
    final js = Directory(path.join(testRoot, 'test-console', 'js'));
    print('Clean up JavaScript test runners from ${js.projectPath}...');
    futures.addAll(_clean(js, _jsExts));
    final wasm = Directory(path.join(testRoot, 'test-console', 'wasm'));
    print('Clean up Web Assembly test runners from ${wasm.projectPath}...');
    futures.addAll(_clean(wasm, _wasmExts));
  }

  if (takeArg(args, 'js')) {
    final js = Directory(path.join(testRoot, 'workers', 'js'));
    print('Clean up JavaScript workers from ${js.projectPath}...');
    futures.addAll(_clean(js, _jsExts));
  }

  if (takeArg(args, 'wasm')) {
    final wasm = Directory(path.join(testRoot, 'workers', 'wasm'));
    print('Clean up Web Assembly workers from ${wasm.projectPath}...');
    futures.addAll(_clean(wasm, _wasmExts));
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
