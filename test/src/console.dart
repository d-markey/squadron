import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:squadron/squadron.dart';
import 'package:squadron/version.dart';
import 'package:web/web.dart';

import 'console_to_html.dart';
import 'html_helpers.dart';
import 'runner_message.dart';
import 'test_runner.dart' as runner;

@JS()
external JSPromise loadFragments();

typedef TestPlatform = SquadronPlatformType;

void main() async {
  document.title = 'Squadron $version Test Console';
  final testRunner = document.iframe('test-runner');
  window.setProperty('dartPrint'.toJS, testRunner.notify.toJS);

  final cancelButton = document.button('tests-cancel');
  final consoleStatus = document.findById('console-status')!;
  void $setStatus(String status) {
    consoleStatus.textContent = status;
  }

  var testRunnerCompleter = Completer<void>();

  window.onMessage.listen((m) {
    final msg = m.data.dartify().toString();
    if (msg == RunnerMessage.ready) {
      if (!testRunnerCompleter.isCompleted) {
        testRunnerCompleter.complete();
      }
    } else if (msg == RunnerMessage.started) {
      cancelButton.disabled = false;
    } else if (msg == RunnerMessage.done) {
      cancelButton.disabled = true;
    } else {
      $setStatus(msg);
    }
  });

  var runnerPlatform = js, workersPlatform = js;

  final wasmRunner = document.input('wasm-runner');
  final wasmWorkers = document.input('wasm-workers');
  final jsRunner = document.input('js-runner');
  final jsWorkers = document.input('js-workers');

  void $setPlatformButtons({TestPlatform? runner, TestPlatform? workers}) {
    runnerPlatform = runner ?? runnerPlatform;
    jsRunner.className = runnerPlatform.isJs ? 'on' : 'off';
    wasmRunner.className = runnerPlatform.isWasm ? 'on' : 'off';
    workersPlatform = workers ?? workersPlatform;
    jsWorkers.className = workersPlatform.isJs ? 'on' : 'off';
    wasmWorkers.className = workersPlatform.isWasm ? 'on' : 'off';
  }

  jsRunner.onClick.listen((_) => $setPlatformButtons(runner: js));
  wasmRunner.onClick.listen((_) => $setPlatformButtons(runner: wasm));
  jsWorkers.onClick.listen((_) => $setPlatformButtons(workers: js));
  wasmWorkers.onClick.listen((_) => $setPlatformButtons(workers: wasm));

  String $getTestRunnerUrl() =>
      'test_runner_${runnerPlatform.code}2${workersPlatform.code}.html?ts=${DateTime.now().millisecondsSinceEpoch}';

  final tests = <String, HTMLInputElement>{};

  void $launch([MouseEvent? _]) async {
    await loadFragments().toDart;
    final testIds = <String>[];
    for (var entry in tests.entries) {
      if (entry.value.checked) {
        testIds.add(entry.key);
      }
    }
    if (testIds.isNotEmpty) {
      testRunnerCompleter = Completer();
      testRunnerCompleter.future.then((_) {
        testRunner.notify(RunnerMessage.launch(testIds).toJS);
      });
      testRunner.src = $getTestRunnerUrl();
    }
  }

  void $selectAll([MouseEvent? _]) {
    for (var checkbox in tests.values) {
      checkbox.checked = true;
    }
  }

  void $deselectAll([MouseEvent? _]) {
    for (var checkbox in tests.values) {
      checkbox.checked = false;
    }
  }

  void $toggle([MouseEvent? _]) {
    for (var checkbox in tests.values) {
      checkbox.checked = !checkbox.checked;
    }
  }

  void $cancel([MouseEvent? _]) async {
    testRunner.notify(RunnerMessage.cancel.toJS);
    cancelButton.disabled = true;
  }

  void $nextError([MouseEvent? _]) {
    testRunner.notify(RunnerMessage.nextError.toJS);
  }

  void $prevError([MouseEvent? _]) {
    testRunner.notify(RunnerMessage.previousError.toJS);
  }

  void $clear([MouseEvent? _]) async {
    testRunner.notify(RunnerMessage.clear.toJS);
  }

  document.button('tests-run-selected').onClick.listen($launch);
  document.button('tests-select-all').onClick.listen($selectAll);
  document.button('tests-deselect-all').onClick.listen($deselectAll);
  document.button('tests-toggle').onClick.listen($toggle);

  cancelButton.onClick.listen($cancel);

  document.button('log-clear').onClick.listen($clear);

  document.button('error-next').onClick.listen($nextError);
  document.button('error-previous').onClick.listen($prevError);

  $setStatus('Test discovery in progress...');
  Log.writeln('Test discovery in progress...');

  final rootGroups = (await runner.discover()).toList();

  rootGroups.sort((a, b) => a.label.compareTo(b.label));

  var testCount = 0;
  final testList = document.findById<HTMLElement>('test-list')!;
  for (var g in rootGroups) {
    final testGroup = document.createDiv(), lbl = testGroup.appendLabel();

    tests[g.label] = lbl.appendCheckbox(id: CSS.escape(g.label), checked: true);

    var label = g.label;
    if (label.startsWith('- ')) label = label.substring(2);
    label += ' (${g.tests} tests)';
    lbl.appendSpan(text: label);

    testList.appendChild(testGroup);
    testCount += g.tests;
  }

  Log.writeln('Discovered $testCount test cases.', [Log.bold]);

  $setStatus('Checking worker versions...');
  Log.writeln('Checking worker versions...');

  await runner.displayVersions();

  $setPlatformButtons();

  $setStatus('Ready');
  Log.writeln('Ready');
  Log.writeln('');
}

const js = TestPlatform.js;
const wasm = TestPlatform.wasm;

extension on TestPlatform {
  String get code {
    if (isJs) return 'js';
    if (isWasm) return 'wasm';
    return 'unsupported';
  }
}
