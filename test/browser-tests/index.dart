import 'dart:html';

import 'package:js/js.dart';

import 'tests_js.dart';

@JS()
external get dartPrint;

@JS()
external set dartPrint(dynamic print);

void main() async {
  final origin = window.location.origin;
  final testRunner = querySelector('#test-runner') as IFrameElement;

  dartPrint = allowInterop((dynamic message) {
    testRunner.contentWindow
        ?.postMessage(message?.toString() ?? '(null)', origin);
  });

  final logHeader = querySelector('#log-header')!;

  final separator = Element.span()..text = ' - ';
  logHeader.append(separator);

  final clearLink = Element.a() as AnchorElement
    ..text = 'Clear'
    ..href = '#'
    ..onClick.listen((e) async {
      testRunner.src = 'test_runner.html';
      await Future.delayed(Duration.zero);
      print('Ready');
      print('');
    });
  logHeader.append(clearLink);

  final buttonBar = querySelector('#button-bar')!;
  final testList = querySelector('#test-list')!;

  void runTests([MouseEvent? _]) async {
    for (var btn in buttonBar.children.whereType<ButtonElement>()) {
      btn.disabled = true;
    }

    final testIds = <String>[];
    for (var test in testList.children.whereType<CheckboxInputElement>()) {
      if (test.checked == true) {
        testIds.add(Uri.encodeQueryComponent(test.id));
      }
    }

    testRunner.src = ((querySelector('#wasm-workers') as CheckboxInputElement)
                .checked ==
            true)
        ? (((querySelector('#wasm-client') as CheckboxInputElement).checked ==
                true)
            ? 'wasm_test_runner_wasm.html?${testIds.join('&')}'
            : 'test_runner_wasm.html?${testIds.join('&')}')
        : 'test_runner_js.html?${testIds.join('&')}';

    // wasm-client not taken into account yet

    for (var btn in buttonBar.children.whereType<ButtonElement>()) {
      btn.disabled = false;
    }
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

  buttonBar.append(ButtonElement()
    ..text = 'Run selected tests'
    ..onClick.listen(runTests));

  buttonBar.append(ButtonElement()
    ..text = 'Select All'
    ..onClick.listen(selectAll));

  buttonBar.append(ButtonElement()
    ..text = 'Deselect All'
    ..onClick.listen(deselectAll));

  buttonBar.append(ButtonElement()
    ..text = 'Toggle'
    ..onClick.listen(toggle));

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
  for (var label in executorLabels) {
    if (n++ > 0) {
      testList.appendHtml(' | ');
    }
    final id = getTestId(label);
    testList.append(CheckboxInputElement()
      ..id = id
      ..checked = true);
    testList.append(LabelElement()
      ..text = label
      ..htmlFor = id);
  }

  print('Ready');
  print('');
}
