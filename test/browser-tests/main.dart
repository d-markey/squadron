@JS()

import 'dart:html';

import 'package:js/js.dart';

import '../worker_services/worker_entry_points.dart';
import '../test_suites/web_worker_test_suite.dart';
import '../test_suites/worker_pool_test_suite.dart';
import '../test_suites/worker_test_suite.dart';
import '../test_suites/local_worker_test_suite.dart';

import 'logger.dart';

@JS()
external get dartPrint;

@JS()
external set dartPrint(value);

void main() async {
  EntryPoints.cache = '/sample_js_workers/cache_worker.dart.js';
  EntryPoints.echo = '/sample_js_workers/echo_worker.dart.js';
  EntryPoints.local = '/sample_js_workers/local_client_worker.dart.js';
  EntryPoints.prime = '/sample_js_workers/prime_worker.dart.js';

  EntryPoints.test = '/sample_js_workers/test_worker.dart.js';
  EntryPoints.failedInit = '/sample_js_workers/test_worker_failing.dart.js';
  EntryPoints.invalidCommand = '/sample_js_workers/test_worker_invalid.dart.js';

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
    try {
      webWorkerTests();
    } catch (e) {
      logger.log('Classic Web Worker tests failed with exception: $e');
    }

    try {
      workerTests();
    } catch (e) {
      logger.log('Squadron Worker tests failed with exception: $e');
    }

    try {
      poolTests();
    } catch (e) {
      logger.log('Squadron Worker Pool tests failed with exception: $e');
    }

    try {
      localWorkerTests();
    } catch (e) {
      logger.log('Squadron Local Worker tests failed with exception: $e');
    }
    runButton.disabled = false;
  });

  logger
    ..log('Ready')
    ..log('');
}
