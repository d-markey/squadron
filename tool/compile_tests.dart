import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:path/path.dart' as path;
import 'package:squadron/squadron.dart';
import 'package:synchronize/synchronize.dart';

import '_helpers.dart';

final token = CancelableToken();
final semaphore = Semaphore(3, maxCount: 3);

void main(List<String> args) async {
  final sw = Stopwatch()..start();

  ProcessSignal.sigint.watch().listen((_) async {
    if (!token.isCanceled) {
      print('[${sw.elapsed}] Received Ctrl+C, aborting...');
      token.cancel();
    }
  });

  args = overrideDefaultArgs(args, 'all', ['runners', 'js', 'wasm']);

  final testRoot = path.join(projectRoot, 'test');

  final targets = <Compilation>[];

  final compileRunners = takeArg(args, 'runners');
  if (compileRunners) {
    final runnersPath = path.join(testRoot, 'test-console');
    print(
        '[${sw.elapsed}] Compile test runners to ${js.label} & ${wasm.label}...');
    targets.addAll(runners.entries.expand((e) =>
        e.value.entries.map((d) => _build(d, e.key, testRoot, runnersPath))));
  }

  final workerPlatforms = <String>{};
  var platformLabels = '';

  void $registerPlatform(String target, String label) {
    if (workerPlatforms.add(target)) {
      if (platformLabels.isNotEmpty) platformLabels += ' & ';
      platformLabels += label;
    }
  }

  if (takeArg(args, 'js')) $registerPlatform('js', js.label);
  if (takeArg(args, 'wasm')) $registerPlatform('wasm', wasm.label);

  if (workerPlatforms.isNotEmpty) {
    final workersPath = path.join(testRoot, 'workers');
    print('[${sw.elapsed}] Compile test workers to $platformLabels...');
    targets.addAll(workers.entries.expand((e) => e.value.entries
        .where((d) => workerPlatforms.contains(d.key))
        .map((d) => _build(d, e.key, workersPath, workersPath))));
  }

  reportUnknownArgs(args);

  try {
    final results = await Future.wait(targets.map((t) => _compile(t, sw)));
    final date = DateTime.now().toUtc();
    await Future.wait([
      if (compileRunners)
        _updateCompilationDate('runners', 'Test Console', date),
      if (platformLabels.contains(js.label))
        _updateCompilationDate('js', '${js.label} Workers', date),
      if (platformLabels.contains(wasm.label))
        _updateCompilationDate('wasm', '${wasm.label} Workers', date),
    ]);

    final exitCode = results.where((e) => e != 0).firstOrNull ?? 0;
    print('[${sw.elapsed}] Date/time: ${date.toIso8601String()}');
    print((exitCode == 0)
        ? '[${sw.elapsed}] Done.'
        : '[${sw.elapsed}] Unknown error $exitCode.');
    exit(exitCode);
  } on CanceledException {
    print('[${sw.elapsed}] Date/time: ${DateTime.now().toIso8601String()}');
    print('[${sw.elapsed}] Aborted');
    exit(1);
  } catch (ex, st) {
    print('[${sw.elapsed}] Date/time: ${DateTime.now().toIso8601String()}');
    print('[${sw.elapsed}] ${ex.runtimeType}: $ex');
    print(st);
    exit(255);
  }
}

Compilation _build(MapEntry<String, ({String folder, int opt})> info,
        String src, String sourceFolder, String outputFolder) =>
    Compilation(
      platform: info.key,
      optimizationLevel: info.value.opt,
      source: path.join(sourceFolder, info.value.folder, src),
      output: path.join(outputFolder, info.key, '$src.${info.key}'),
    );

Future<int> _compile(Compilation compilation, Stopwatch sw) async {
  final t = await semaphore.enter();
  try {
    token.throwIfCanceled();
    final process = await compilation.start();
    token.onCanceled.then((_) => process.kill());
    final (:exitCode, :output) = await process.result;
    final src = compilation.source, compiled = compilation.output;
    if (token.isCanceled) {
      print('[${sw.elapsed}] * $src --> $compiled: cancelled ($exitCode)');
      token.throwIfCanceled();
    } else if (exitCode == 0) {
      print('[${sw.elapsed}] * $src --> $compiled: success');
    } else {
      print([
        '[${sw.elapsed}] * $src --> $compiled: error $exitCode',
        ...output.map((l) => '[${sw.elapsed}]     $l'),
      ].join('\n'));
    }
    return exitCode;
  } finally {
    t.release();
  }
}

Future<void> _updateCompilationDate(
    String target, String label, DateTime date) async {
  final htmlFile = path.join(projectRoot, 'test', 'test-console', 'includes',
      'compilation_date_$target.inc.html');
  await File(htmlFile).writeAsString(
      '<span><b>$label</b> compiled on <b>${datePart(date)} ${timePart(date)} GMT</b></span>');
}

String datePart(DateTime d) => '${d.year}-${nn(d.month)}-${nn(d.day)}';
String timePart(DateTime d) => '${nn(d.hour)}:${nn(d.minute)}:${nn(d.second)}';
String nn(int n) => n.toString().padLeft(2, '0');

sealed class Optimizations {
  static const none = 0;
  static const def = 1;
  static const safe = 2;
  static const unsafe = 3;
  static const aggressive = 4;
}

extension type Compilation._(List<String> _args) {
  Compilation({
    required String platform,
    required int optimizationLevel,
    required String source,
    required String output,
  }) : _args = List.unmodifiable([
          'compile',
          platform,
          '-O$optimizationLevel',
          source,
          '-o',
          output,
        ]);

  String get source => File(_args[3]).projectPath;
  String get output => File(_args[5]).projectPath;

  Future<Process> start() {
    print('*** dart ${_args.join(' ')}');
    return Process.start('dart', _args);
  }
}

extension on Process {
  Future<({int exitCode, List<String> output})> get result async {
    final output = <String>[], append = _append(output);
    final subs = [this.stdout.listen(append), this.stderr.listen(append)];
    int exitCode;
    try {
      exitCode = await this.exitCode;
    } catch (ex, st) {
      exitCode = 255;
      output.add('${ex.runtimeType}: $ex');
      output.add(st.toString());
    } finally {
      for (var sub in subs) {
        sub.cancel();
      }
    }
    return (exitCode: exitCode, output: output);
  }

  static final _eol = RegExp('\r|\n');

  static void Function(List<int>) _append(List<String> output) =>
      (List<int> data) {
        final str = utf8.decode(data);
        output.addAll(str.split(_eol).where((l) => l.isNotEmpty));
      };
}

const js = SquadronPlatformType.js;
const wasm = SquadronPlatformType.wasm;

const workers = {
  'cache_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.aggressive),
    'wasm': (folder: 'js', opt: Optimizations.aggressive),
  },
  'echo_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.aggressive),
    'wasm': (folder: 'wasm', opt: Optimizations.aggressive),
  },
  'error_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.none), // no optim
    'wasm': (folder: 'js', opt: Optimizations.none), // no optim
  },
  'installable_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.aggressive),
    'wasm': (folder: 'js', opt: Optimizations.aggressive),
  },
  'issues_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.aggressive),
    'wasm': (folder: 'js', opt: Optimizations.aggressive),
  },
  'local_client_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.aggressive),
    'wasm': (folder: 'js', opt: Optimizations.aggressive),
  },
  'log_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.aggressive),
    'wasm': (folder: 'js', opt: Optimizations.aggressive),
  },
  'not_a_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.aggressive),
    'wasm': (folder: 'js', opt: Optimizations.aggressive),
  },
  'person_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.safe),
    'wasm': (folder: 'js', opt: Optimizations.safe),
  },
  'prime_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.aggressive),
    'wasm': (folder: 'js', opt: Optimizations.aggressive),
  },
  'streaming_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.aggressive),
    'wasm': (folder: 'js', opt: Optimizations.aggressive),
  },
  'test_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.safe),
    'wasm': (folder: 'js', opt: Optimizations.safe),
  },
};

const runners = {
  'console.dart': {
    'js': (folder: 'src', opt: Optimizations.def),
  },
  'runner_js_workers.dart': {
    'js': (folder: 'src', opt: Optimizations.def),
    'wasm': (folder: 'src', opt: Optimizations.def),
  },
  'runner_wasm_workers.dart': {
    'js': (folder: 'src', opt: Optimizations.def),
    'wasm': (folder: 'src', opt: Optimizations.def),
  },
};
