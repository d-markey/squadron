@JS()

import 'dart:html';

import 'package:js/js.dart';

import 'tests.dart';

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
  final clearLink = Element.a()
    ..text = 'Clear'
    ..attributes['href'] = '#';
  clearLink.onClick.listen((e) async {
    testRunner.src = 'test_runner.html';
    await Future.delayed(Duration.zero);
    dartPrint('Ready');
    dartPrint('');
  });
  logHeader.append(clearLink);

  final buttonBar = querySelector('#button-bar')!;
  final testList = querySelector('#test-list')!;

  void runTests() async {
    for (var btn in buttonBar.children.whereType<ButtonElement>()) {
      btn.disabled = true;
    }

    final testIds = <String>[];
    for (var test in testList.children.whereType<CheckboxInputElement>()) {
      if (test.checked == true) {
        testIds.add(Uri.encodeQueryComponent(test.id));
      }
    }
    testRunner.src = 'test_runner.html?${testIds.join('&')}';

    for (var btn in buttonBar.children.whereType<ButtonElement>()) {
      btn.disabled = false;
    }
  }

  void selectAll() async {
    for (var test in testList.children.whereType<CheckboxInputElement>()) {
      test.checked = true;
    }
  }

  void deselectAll() async {
    for (var test in testList.children.whereType<CheckboxInputElement>()) {
      test.checked = false;
    }
  }

  void toggle() async {
    for (var test in testList.children.whereType<CheckboxInputElement>()) {
      test.checked = !(test.checked ?? false);
    }
  }

  final runButton = buttonBar
      .append(ButtonElement()..text = 'Run selected tests') as ButtonElement;
  runButton.onClick.listen((m) => runTests());

  final allButton =
      buttonBar.append(ButtonElement()..text = 'Select All') as ButtonElement;
  allButton.onClick.listen((m) => selectAll());

  final noneButton =
      buttonBar.append(ButtonElement()..text = 'Deselect All') as ButtonElement;
  noneButton.onClick.listen((m) => deselectAll());

  final toggleButton =
      buttonBar.append(ButtonElement()..text = 'Toggle') as ButtonElement;
  toggleButton.onClick.listen((m) => toggle());

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

  dartPrint('Ready');
  dartPrint('');
}
