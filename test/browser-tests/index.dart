import 'dart:async';
import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:web/web.dart';

import 'html_helpers.dart';
import 'runner_message.dart';
import 'test_runner.dart' as runner;

void main() async {
  final testRunner = document.findById<HTMLIFrameElement>('test-runner')!;

  void $notify(JSAny? message) {
    testRunner.notify(message);
  }

  final logStatus = document.findById<HTMLSpanElement>('log-status')!;
  void $setStatus(Object? status) {
    logStatus.innerText = ' - ${status ?? '(null)'}';
  }

  var testRunnerCompleter = Completer<void>();

  window.onMessage.listen((m) {
    final msg = m.data.toRunnerMessage;
    if (msg == RunnerMessage.ready) {
      if (!testRunnerCompleter.isCompleted) {
        testRunnerCompleter.complete();
      }
    } else {
      $setStatus(msg.message);
    }
  });

  final wasmClient = document.createCheckbox(id: 'wasm-client');
  final wasmWorkers = document.createCheckbox(id: 'wasm-workers');

  String $getTestRunnerUrl() {
    final client = wasmClient.checked ? 'wasm' : 'js';
    final workers = wasmWorkers.checked ? 'wasm' : 'js';
    return 'test_runner_${client}2$workers.html';
  }

  final tests = <String, HTMLInputElement>{};

  void $launch([MouseEvent? _]) async {
    final testIds = <String>[];
    for (var entry in tests.entries) {
      if (entry.value.checked) {
        testIds.add(entry.key);
      }
    }
    if (testIds.isNotEmpty) {
      testRunnerCompleter = Completer();
      testRunnerCompleter.future.then((_) {
        $notify(RunnerMessage.launch(testIds).toJS);
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

  Future<void> $cancel([MouseEvent? _]) async {
    $notify(RunnerMessage.cancelled.toJS);
    await pumpEventQueue();
  }

  void $clear([MouseEvent? _]) async {
    await $cancel();
    testRunner.src = $getTestRunnerUrl();
    $setStatus('Ready');
    $notify('Ready'.toJS);
    $notify(''.toJS);
  }

  final logHeader = document.findById<HTMLSpanElement>('log-header')!;
  logHeader.appendSpan(text: ' - ');
  logHeader.appendAnchor(text: 'Clear', href: '#', onClick: $clear);

  final buttonBar = document.findById<HTMLDivElement>('button-bar')!;
  buttonBar.appendButton(label: 'Run selected tests', onClick: $launch);
  buttonBar.appendButton(label: 'Select All', onClick: $selectAll);
  buttonBar.appendButton(label: 'Deselect All', onClick: $deselectAll);
  buttonBar.appendButton(label: 'Toggle', onClick: $toggle);
  buttonBar.appendButton(label: 'Cancel', onClick: $cancel);
  buttonBar.appendChild(wasmWorkers);
  buttonBar.appendLabel(text: 'Web Assembly Workers', target: wasmWorkers);
  buttonBar.appendChild(wasmClient);
  buttonBar.appendLabel(text: 'Web Assembly Client', target: wasmClient);

  $setStatus('Test discovery in progress...');
  $notify('Test discovery in progress...'.toJS);

  final rootGroups = await runner.discover();

  var n = 0;
  final testList = document.findById<HTMLDivElement>('test-list')!;
  for (var g in rootGroups) {
    if (n++ > 0) testList.appendSpan(text: ' | ');
    final label = '${g.label} (${g.tests} tests)';
    final checkbox = document.createCheckbox(id: CSS.escape(g.label));
    checkbox.checked = true;
    tests[g.label] = checkbox;
    testList.appendChild(checkbox);
    testList.appendLabel(text: label, target: checkbox);
  }

  $setStatus('Ready');
  $notify('Ready'.toJS);
  $notify(''.toJS);
}
