@JS()

import 'dart:html';

import 'package:js/js.dart';
import 'package:squadron/squadron.dart';

import '../test_suites/cancelation_test_suite.dart' as cancelation_test;
import '../test_suites/issues_test_suite.dart' as issues_test;
import '../test_suites/local_worker_test_suite.dart' as local_worker_test;
import '../test_suites/logger_test_suite.dart' as logger_test;
import '../test_suites/squadron_singleton_test_suite.dart'
    as squadron_singleton_test;
import '../test_suites/web_worker_test_suite.dart' as web_worker_test;
import '../test_suites/worker_pool_test_suite.dart' as worker_pool_test;
import '../test_suites/worker_test_suite.dart' as worker_test;
import '../worker_services/_test_context.dart';
import 'logger.dart';

@JS()
external get dartPrint;

@JS()
external set dartPrint(value);

void main() async {
  await TestContext.init('/');

  final logger = Logger(querySelector('#output') as DivElement);

  dartPrint = allowInterop(
      (dynamic message) => logger.print(message?.toString() ?? ''));

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

  runButton.onClick.listen((MouseEvent m) {
    runButton.disabled = true;

    Squadron.shutdown();

    try {
      squadron_singleton_test.main();
    } catch (e) {
      logger.log('Squadron singleton tests failed with exception: $e');
    }

    Squadron.setId('workerTests');
    Squadron.logLevel = SquadronLogLevel.off;

    try {
      logger_test.main();
    } catch (e) {
      logger.log('Logger tests failed with exception: $e');
    }

    try {
      web_worker_test.main();
    } catch (e) {
      logger.log('Classic Web Worker tests failed with exception: $e');
    }

    try {
      worker_test.main();
    } catch (e) {
      logger.log('Squadron Worker tests failed with exception: $e');
    }

    try {
      worker_pool_test.main();
    } catch (e) {
      logger.log('Squadron Worker Pool tests failed with exception: $e');
    }

    try {
      local_worker_test.main();
    } catch (e) {
      logger.log('Squadron Local Worker tests failed with exception: $e');
    }

    try {
      cancelation_test.main();
    } catch (e) {
      logger.log('Cancelation tests failed with exception: $e');
    }

    try {
      issues_test.main();
    } catch (e) {
      logger.log('Issues tests failed with exception: $e');
    }

    runButton.disabled = false;
  });

  logger
    ..log('Ready')
    ..log('');
}
