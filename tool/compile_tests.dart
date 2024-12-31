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
  print('Date/time: ${DateTime.now().toIso8601String()}');
  final sw = Stopwatch()..start();

  ProcessSignal.sigint.watch().listen((_) async {
    if (!token.isCanceled) {
      print('Received Ctrl+C, aborting...');
      token.cancel();
    }
  });

  args = overrideDefaultArgs(args, 'all', ['runners', 'js', 'wasm']);

  final test = path.join(projectRoot, 'test');

  final targets = <Compilation>[];

  if (takeArg(args, 'runners')) {
    print('Compile browser test runners to ${js.label} & ${wasm.label}...');
    final runnersPath = path.join(test, 'browser-tests');
    targets
        .addAll(runners.entries.expand<Compilation>((e) => e.value.entries.map(
              (d) => Compilation(
                platform: d.key,
                optimizationLevel: d.value.opt,
                source: path.join(runnersPath, d.value.folder, e.key),
                output: path.join(runnersPath, '${e.key}.${d.key}'),
              ),
            )));
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
    final workersPath = path.join(test, 'workers');
    print('Compile test workers to $platformLabels...');
    targets.addAll(workers.entries.expand<Compilation>((e) =>
        e.value.entries.where((d) => workerPlatforms.contains(d.key)).map(
              (d) => Compilation(
                platform: d.key,
                optimizationLevel: d.value.opt,
                source: path.join(workersPath, d.value.folder, e.key),
                output: path.join(workersPath, d.key, '${e.key}.${d.key}'),
              ),
            )));
  }

  reportUnknownArgs(args);

  try {
    final results = await Future.wait(targets.map(_compile));
    final exitCode = results.where((e) => e != 0).firstOrNull ?? 0;
    print((exitCode == 0)
        ? 'Done in ${sw.elapsed}.'
        : 'Unknown error $exitCode.');
    exit(exitCode);
  } on CanceledException {
    print('Aborted');
    exit(1);
  } catch (ex, st) {
    print('${ex.runtimeType}: $ex');
    print(st);
    exit(255);
  }
}

Future<int> _compile(Compilation compilation) async {
  final t = await semaphore.enter();
  try {
    token.throwIfCanceled();
    final process = await compilation.start();
    token.onCanceled.then((_) => process.kill());
    final (:exitCode, :output) = await process.result;
    final src = compilation.source, compiled = compilation.output;
    if (token.isCanceled) {
      print('* $src --> $compiled: cancelled ($exitCode)');
      token.throwIfCanceled();
    } else if (exitCode == 0) {
      print('* $src --> $compiled: success');
    } else {
      print([
        '* $src --> $compiled: error $exitCode',
        ...output.map((l) => '     $l'),
      ].join('\n'));
    }
    return exitCode;
  } finally {
    t.release();
  }
}

sealed class Optimizations {
  static const none = 0;
  static const def = 1;
  static const safe = 2;
  static const unsafe = 3;
  static const agressive = 4;
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

  Future<Process> start() => Process.start('dart', _args);
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
    'js': (folder: 'js', opt: Optimizations.safe),
    'wasm': (folder: 'js', opt: Optimizations.safe),
  },
  'echo_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.safe),
    'wasm': (folder: 'wasm', opt: Optimizations.safe),
  },
  'installable_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.safe),
    'wasm': (folder: 'js', opt: Optimizations.safe),
  },
  'issues_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.unsafe),
    'wasm': (folder: 'js', opt: Optimizations.unsafe),
  },
  'prime_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.unsafe),
    'wasm': (folder: 'js', opt: Optimizations.unsafe),
  },
  'not_a_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.unsafe),
    'wasm': (folder: 'js', opt: Optimizations.unsafe),
  },
  'log_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.safe),
    'wasm': (folder: 'js', opt: Optimizations.safe),
  },
  'test_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.def),
    'wasm': (folder: 'js', opt: Optimizations.def),
  },
  'streaming_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.safe),
    'wasm': (folder: 'js', opt: Optimizations.safe),
  },
  'local_client_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.safe),
    'wasm': (folder: 'js', opt: Optimizations.safe),
  },
  'error_worker.dart': {
    'js': (folder: 'js', opt: Optimizations.none), // no optim
    'wasm': (folder: 'js', opt: Optimizations.none), // no optim
  },
};

const runners = {
  'index.dart': {
    'js': (folder: '', opt: Optimizations.agressive),
  },
  'runner_js_workers.dart': {
    'js': (folder: '', opt: Optimizations.def),
    'wasm': (folder: '', opt: Optimizations.none),
  },
  'runner_wasm_workers.dart': {
    'js': (folder: '', opt: Optimizations.def),
    'wasm': (folder: '', opt: Optimizations.none),
  },
};
