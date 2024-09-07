import 'dart:html';

import 'package:js/js.dart';

import '../classes/test_context.dart';
import 'test_runner.dart';

@JS()
external get dartPrint;

@JS()
external set dartPrint(dynamic print);

void main() async {
  await discoverTests();

  final origin = window.location.origin;
  final testRunner = querySelector('#test-runner') as IFrameElement;

  dartPrint = allowInterop((dynamic message) {
    testRunner.contentWindow
        ?.postMessage(message?.toString() ?? '(null)', origin);
  });

  final logStatus = querySelector('#log-status')!;

  void setStatus(String status) {
    logStatus.innerText = ' - $status';
  }

  window.onMessage.listen((m) => setStatus(m.data?.toString() ?? '(null)'));

  final logHeader = querySelector('#log-header')!;

  final separator = Element.span()..text = ' - ';
  logHeader.append(separator);

  String getTestRunnerUrl() {
    final client =
        ((querySelector('#wasm-client') as CheckboxInputElement).checked ==
                true)
            ? 'test_runner_wasm'
            : 'test_runner_js';

    final workers =
        ((querySelector('#wasm-workers') as CheckboxInputElement).checked ==
                true)
            ? 'wasm'
            : 'js';

    return '${client}2$workers.html';
  }

  final clearLink = Element.a() as AnchorElement
    ..text = 'Clear'
    ..href = '#'
    ..onClick.listen((e) async {
      testRunner.src = getTestRunnerUrl();
      await Future.delayed(Duration.zero);
      print('Ready');
      print('');
    });
  logHeader.append(clearLink);

  final buttonBar = querySelector('#button-bar')!;
  final testList = querySelector('#test-list')!;

  void executeTests([MouseEvent? _]) async {
    final testIds = <String>[];
    for (var test in testList.children.whereType<CheckboxInputElement>()) {
      if (test.checked == true) {
        testIds.add(Uri.encodeQueryComponent(test.id));
      }
    }

    testRunner.src = '${getTestRunnerUrl()}?${testIds.join('&')}';
  }

  void selectAll([MouseEvent? _]) async {
    for (var test in testList.children.whereType<CheckboxInputElement>()) {
      test.checked = true;
    }
  }

  void deselectAll([MouseEvent? _]) async {
    for (var test in testList.children.whereType<CheckboxInputElement>()) {
      test.checked = false;
    }
  }

  void toggle([MouseEvent? _]) async {
    for (var test in testList.children.whereType<CheckboxInputElement>()) {
      test.checked = !(test.checked ?? false);
    }
  }

  void cancel([MouseEvent? _]) {
    testRunner.contentWindow?.postMessage(TestContext.cancelled, origin);
  }

  buttonBar.append(ButtonElement()
    ..text = 'Run selected tests'
    ..onClick.listen(executeTests));

  buttonBar.append(ButtonElement()
    ..text = 'Select All'
    ..onClick.listen(selectAll));

  buttonBar.append(ButtonElement()
    ..text = 'Deselect All'
    ..onClick.listen(deselectAll));

  buttonBar.append(ButtonElement()
    ..text = 'Toggle'
    ..onClick.listen(toggle));

  buttonBar.append(ButtonElement()
    ..text = 'Cancel'
    ..onClick.listen(cancel));

  buttonBar.append(CheckboxInputElement()
    ..id = 'wasm-workers'
    ..checked = false);
  buttonBar.append(LabelElement()
    ..text = 'Web Assembly Workers'
    ..htmlFor = 'wasm-workers');

  buttonBar.append(CheckboxInputElement()
    ..id = 'wasm-client'
    ..checked = false);
  buttonBar.append(LabelElement()
    ..text = 'Web Assembly Client'
    ..htmlFor = 'wasm-client');

  var n = 0;
  for (var label in TestContext.rootGroups) {
    if (n++ > 0) {
      testList.appendHtml(' | ');
    }
    testList.append(CheckboxInputElement()
      ..id = label
      ..checked = true);
    testList.append(LabelElement()
      ..text = label
      ..htmlFor = label);
  }

  setStatus('Ready');
  print('Ready');
  print('');
}
