@JS()

import 'dart:html';

import 'package:js/js.dart';

import '../classes/worker_entry_points.dart';
import '../test_suites/web_worker_test_suite.dart';
import '../test_suites/worker_pool_test_suite.dart';
import '../test_suites/worker_test_suite.dart';

import 'logger.dart';

@JS()
external get dartPrint;

@JS()
external set dartPrint(value);

void main() async {
  setEntryPoint('cache', '/sample_js_workers/cache_worker.dart.js');
  setEntryPoint('bitcoin', '/sample_js_workers/bitcoin_worker.dart.js');
  setEntryPoint('prime', '/sample_js_workers/prime_worker.dart.js');
  setEntryPoint('pi_digits', '/sample_js_workers/pi_digits_worker.dart.js');
  setEntryPoint('rogue', '/sample_js_workers/rogue_worker.dart.js');
  setEntryPoint('sample', '/sample_js_workers/sample_worker.dart.js');
  setEntryPoint('echo', '/sample_js_workers/echo_worker.dart.js');

  final logger = Logger(querySelector('#output') as DivElement);

  dartPrint = allowInterop(
      (dynamic message) => logger.print(message?.toString() ?? ''));

  final logHeader = querySelector('#log-header')!;
  final separator = Element.span();
  separator.text = ' - ';
  logHeader.append(separator);
  final clearLink = Element.a();
  clearLink.text = 'Clear';
  clearLink.attributes['href'] = '#';
  clearLink.onClick.listen((MouseEvent e) {
    logger.clear();
    logger.log('Ready');
    logger.log('');
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
    runButton.disabled = false;
  });

  logger.log('Ready');
  logger.log('');
}
