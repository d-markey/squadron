import 'dart:js_interop';

import 'package:web/web.dart';

import 'tests.dart';

@JS()
external JSFunction get dartPrint;

@JS()
external set dartPrint(JSFunction value);

void main() async {
  final origin = window.location.origin.jsify()!;
  final testRunner = querySelector('#test-runner') as HTMLIFrameElement;

  dartPrint = (JSAny? message) {
    testRunner.contentWindow?.postMessage(message ?? '(null)'.jsify(), origin);
  }.toJS;

  final logHeader = querySelector('#log-header')!;
  final separator = HTMLSpanElement()..text = ' - ';
  logHeader.appendChild(separator);
  final clearLink = HTMLAnchorElement()
    ..text = 'Clear'
    ..setAttribute('href', '#');
  clearLink.onClick.listen((e) async {
    testRunner.src = 'test_runner.html';
    await Future.delayed(Duration.zero);
    dartPrint.callAsFunction('Ready'.jsify());
    dartPrint.callAsFunction(''.jsify());
  });
  logHeader.appendChild(clearLink);

  final buttonBar = querySelector('#button-bar')!;
  final testList = querySelector('#test-list')!;

  void runTests() async {
    for (var i = 0; i < buttonBar.children.length; i++) {
      final btn = buttonBar.children.item(i);
      if (btn is HTMLButtonElement) {
        btn.disabled = true;
      }
    }

    final testIds = <String>[];
    for (var i = 0; i < testList.children.length; i++) {
      final test = testList.children.item(i);
      if (test is HTMLInputElement &&
          test.type == 'checkbox' &&
          test.checked == true) {
        testIds.add(Uri.encodeQueryComponent(test.id));
      }
    }
    testRunner.src = 'test_runner.html?${testIds.join('&')}';

    for (var i = 0; i < buttonBar.children.length; i++) {
      final btn = buttonBar.children.item(i);
      if (btn is HTMLButtonElement) {
        btn.disabled = false;
      }
    }
  }

  void selectAll() async {
    for (var i = 0; i < testList.children.length; i++) {
      final test = testList.children.item(i);
      if (test is HTMLInputElement &&
          test.type == 'checkbox' &&
          test.checked == false) {
        test.checked = true;
      }
    }
  }

  void deselectAll() async {
    for (var i = 0; i < testList.children.length; i++) {
      final test = testList.children.item(i);
      if (test is HTMLInputElement &&
          test.type == 'checkbox' &&
          test.checked == true) {
        test.checked = false;
      }
    }
  }

  void toggle() async {
    for (var i = 0; i < testList.children.length; i++) {
      final test = testList.children.item(i);
      if (test is HTMLInputElement && test.type == 'checkbox') {
        test.checked = !test.checked;
      }
    }
  }

  final runButton =
      buttonBar.appendChild(HTMLButtonElement()..text = 'Run selected tests')
          as HTMLButtonElement;
  runButton.onClick.listen((m) => runTests());

  final allButton =
      buttonBar.appendChild(HTMLButtonElement()..text = 'Select All')
          as HTMLButtonElement;
  allButton.onClick.listen((m) => selectAll());

  final noneButton =
      buttonBar.appendChild(HTMLButtonElement()..text = 'Deselect All')
          as HTMLButtonElement;
  noneButton.onClick.listen((m) => deselectAll());

  final toggleButton = buttonBar
      .appendChild(HTMLButtonElement()..text = 'Toggle') as HTMLButtonElement;
  toggleButton.onClick.listen((m) => toggle());

  var n = 0;
  for (var label in executorLabels) {
    if (n++ > 0) {
      testList.innerHTML += ' | ';
    }
    final id = getTestId(label);
    testList.appendChild(HTMLInputElement()
      ..id = id
      ..type = 'checkbox'
      ..checked = true);
    testList.appendChild(HTMLLabelElement()
      ..text = label
      ..htmlFor = id);
  }

  dartPrint.callAsFunction('Ready'.jsify());
  dartPrint.callAsFunction(''.jsify());
}
