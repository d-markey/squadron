import 'dart:js_interop';

import 'package:web/helpers.dart';
import 'package:web/web.dart';

import 'tests.dart';

@JS()
external JSFunction? get dartPrint;

@JS()
external set dartPrint(JSFunction? value);

bool isCheckbox(Element? element) => (element != null &&
    element.tagName.toLowerCase() == 'input' &&
    (element as HTMLInputElement).type.toLowerCase() == 'checkbox');

void main(dynamic args) {
  final origin = window.location.origin.jsify()!;
  final testRunner = querySelector('#test-runner') as HTMLIFrameElement;

  dartPrint = (JSAny? message) {
    testRunner.contentWindow?.postMessage(
      (message ?? '(null)').jsify(),
      origin,
    );
  }.toJS;

  final logHeader = querySelector('#log-header')!;

  logHeader.appendChild(document.createElement('span')..text = ' - ');

  logHeader.appendChild(document.createElement('a') as HTMLAnchorElement
    ..text = 'Clear'
    ..href = '#'
    ..onClick.listen((e) async {
      testRunner.src = 'test_runner.html';
      await Future.delayed(Duration(milliseconds: 10));
      print('Ready');
      print('');
    }));

  final buttonBar = querySelector('#button-bar')!;
  final testList = querySelector('#test-list')!;

  void runTests([MouseEvent? _]) {
    for (var i = 0; i < buttonBar.children.length; i++) {
      final btn = buttonBar.children.item(i);
      if (btn != null && btn.tagName == 'button') {
        (btn as HTMLButtonElement).disabled = true;
      }
    }

    final testIds = <String>[];
    for (var i = 0; i < testList.children.length; i++) {
      final test = testList.children.item(i);
      if (isCheckbox(test) && (test as HTMLInputElement).checked == true) {
        testIds.add(Uri.encodeQueryComponent(test.id));
      }
    }
    testRunner.src = 'test_runner.html?${testIds.join('&')}';

    for (var i = 0; i < buttonBar.children.length; i++) {
      final btn = buttonBar.children.item(i);
      if (btn != null && btn.tagName == 'button') {
        (btn as HTMLButtonElement).disabled = false;
      }
    }
  }

  void selectAll([MouseEvent? _]) {
    for (var i = 0; i < testList.children.length; i++) {
      final test = testList.children.item(i);
      if (isCheckbox(test) && (test as HTMLInputElement).checked == false) {
        test.checked = true;
      }
    }
  }

  void deselectAll([MouseEvent? _]) {
    for (var i = 0; i < testList.children.length; i++) {
      final test = testList.children.item(i);
      if (isCheckbox(test) && (test as HTMLInputElement).checked == true) {
        test.checked = false;
      }
    }
  }

  void toggle([MouseEvent? _]) {
    for (var i = 0; i < testList.children.length; i++) {
      final test = testList.children.item(i);
      if (isCheckbox(test)) {
        (test as HTMLInputElement).checked = !test.checked;
      }
    }
  }

  buttonBar.appendChild(document.createElement('button')
    ..text = 'Run selected tests'
    ..onClick.listen(runTests));

  buttonBar.appendChild(document.createElement('button')
    ..text = 'Select All'
    ..onClick.listen(selectAll));

  buttonBar.appendChild(document.createElement('button')
    ..text = 'Deselect All'
    ..onClick.listen(deselectAll));

  buttonBar.appendChild(document.createElement('button')
    ..text = 'Toggle'
    ..onClick.listen(toggle));

  var n = 0;
  for (var label in executorLabels) {
    if (n++ > 0) {
      testList.innerHTML += ' | ';
    }
    final id = getTestId(label);
    testList.appendChild(document.createElement('input')
      ..id = id
      ..setAttribute('type', 'checkbox')
      ..setAttribute('checked', ''));
    testList.appendChild(document.createElement('label')
      ..text = label
      ..setAttribute('for', id));
  }

  print('Ready');
  print('');
}
