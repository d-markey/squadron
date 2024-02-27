@JS()

import 'dart:html';

import 'package:js/js.dart';

import '../cancelation_test.dart' as cancelation_test;
import '../classes/test_context.dart';
import '../issues_test.dart' as issues_test;
import '../local_worker_test.dart' as local_worker_test;
import '../marshaler_test.dart' as marshaler;
import '../web_worker_test.dart' as web_worker_test;
import '../worker_pool_test.dart' as worker_pool_test;
import '../worker_test.dart' as worker_test;
import 'html_logger.dart';

@JS()
external get dartPrint;

@JS()
external set dartPrint(value);

void main() async {
  final htmlLogger = HtmlLogger(querySelector('#output') as DivElement);

  dartPrint = allowInterop(
      (dynamic message) => htmlLogger.print(message?.toString() ?? ''));

  final testContext = await TestContext.init('/');

  final logHeader = querySelector('#log-header')!;
  final separator = Element.span()..text = ' - ';
  logHeader.append(separator);
  final clearLink = Element.a()
    ..text = 'Clear'
    ..attributes['href'] = '#';
  clearLink.onClick.listen((MouseEvent e) {
    htmlLogger
      ..clear()
      ..log('Ready')
      ..log('');
  });
  logHeader.append(clearLink);

  final buttonBar = querySelector('#button-bar')!;

  final runButton = buttonBar.append(ButtonElement()..text = 'Run all tests')
      as ButtonElement;

  runButton.onClick.listen((MouseEvent m) async {
    runButton.disabled = true;

    try {
      await web_worker_test.execute(testContext);
    } catch (e) {
      htmlLogger.log('Classic Web Worker tests failed with exception: $e');
    }

    try {
      await worker_test.execute(testContext);
    } catch (e) {
      htmlLogger.log('Squadron Worker tests failed with exception: $e');
    }

    try {
      await worker_pool_test.execute(testContext);
    } catch (e) {
      htmlLogger.log('Squadron Worker Pool tests failed with exception: $e');
    }

    try {
      await local_worker_test.execute(testContext);
    } catch (e) {
      htmlLogger.log('Squadron Local Worker tests failed with exception: $e');
    }

    try {
      await cancelation_test.execute(testContext);
    } catch (e) {
      htmlLogger.log('Cancelation tests failed with exception: $e');
    }

    try {
      await marshaler.execute(testContext);
    } catch (e) {
      htmlLogger.log('Marshaler tests failed with exception: $e');
    }

    try {
      await issues_test.execute(testContext);
    } catch (e) {
      htmlLogger.log('Issues tests failed with exception: $e');
    }

    runButton.disabled = false;
  });

  htmlLogger
    ..log('Ready')
    ..log('');
}
