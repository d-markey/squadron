@JS()

import 'dart:html';

import 'package:js/js.dart';

import '../builders.dart';
import '../squadron_worker_pool_test_suite.dart';
import '../squadron_worker_test_suite.dart';

import '../worker_services/cache_service.dart';
import '../worker_services/prime_service.dart';
import '../worker_services/rogue_service.dart';
import '../worker_services/sample_service.dart';
import 'logger.dart';

@JS()
external get dartPrint;

@JS()
external set dartPrint(value);

void main() async {
  setWorker<CacheWorker>(([dynamic arg]) =>
      CacheWorker('/sample_js_workers/cache_worker.dart.js'));
  setWorker<PrimeWorker>(([dynamic arg]) => PrimeWorker(
      '/sample_js_workers/prime_worker.dart.js',
      args: [(arg as CacheWorker?)?.channel?.share().serialize()]));
  setWorker<RogueWorker>(([dynamic arg]) =>
      RogueWorker('sample_js_workers/rogue_worker.dart.js'));
  setWorker<SampleWorker>(([dynamic arg]) =>
      SampleWorker('sample_js_workers/sample_worker.dart.js'));

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
      workerTests();
    } catch (e) {
      logger.log('Worker tests failed with exception: $e');
    }

    try {
      poolTests();
    } catch (e) {
      logger.log('Pool tests failed with exception: $e');
    }
    runButton.disabled = false;
  });

  logger.log('Ready');
  logger.log('');
}
