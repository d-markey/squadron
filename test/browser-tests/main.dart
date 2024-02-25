@JS()

import 'dart:html';

import 'package:js/js.dart';

import '../cancelation_test.dart' as cancelation_test;
import '../classes/test_context.dart';
import '../issues_test.dart' as issues_test;
import '../local_worker_test.dart' as local_worker_test;
import '../web_worker_test.dart' as web_worker_test;
import '../worker_pool_test.dart' as worker_pool_test;
import '../worker_test.dart' as worker_test;
import 'logger.dart';

@JS()
external get dartPrint;

@JS()
external set dartPrint(value);

void main() async {
  final logger = Logger(querySelector('#output') as DivElement);

  dartPrint = allowInterop(
      (dynamic message) => logger.print(message?.toString() ?? ''));

  final testContext = await TestContext.init('/');

  final logHeader = querySelector('#log-header')!;
  final separator = Element.span()..text = ' - ';
  logHeader.append(separator);
  final clearLink = Element.a()
    ..text = 'Clear'
    ..attributes['href'] = '#';
  clearLink.onClick.listen((MouseEvent e) {
    logger
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
      logger.log('Classic Web Worker tests failed with exception: $e');
    }

    try {
      await worker_test.execute(testContext);
    } catch (e) {
      logger.log('Squadron Worker tests failed with exception: $e');
    }

    try {
      await worker_pool_test.execute(testContext);
    } catch (e) {
      logger.log('Squadron Worker Pool tests failed with exception: $e');
    }

    try {
      await local_worker_test.execute(testContext);
    } catch (e) {
      logger.log('Squadron Local Worker tests failed with exception: $e');
    }

    try {
      await cancelation_test.execute(testContext);
    } catch (e) {
      logger.log('Cancelation tests failed with exception: $e');
    }

    try {
      await issues_test.execute(testContext);
    } catch (e) {
      logger.log('Issues tests failed with exception: $e');
    }

    runButton.disabled = false;
  });

  logger
    ..log('Ready')
    ..log('');
}
