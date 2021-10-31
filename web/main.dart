import 'dart:html';

import 'expect.dart';
import 'prime_worker_test_suite.dart';
import 'rogue_worker_test_suite.dart';
import 'sample_worker_pool_test_suite.dart';
import 'logger.dart';
import 'sample_worker_test_suite.dart';

typedef UnitTest = Future<bool> Function(
    Logger logger, Map<String, String> entryPoints);

Map<String, String> _entryPoints = {
  'cache': '/sample_js_workers/cache_worker.dart.js',
  'bitcoin': '/sample_js_workers/bitcoin_worker.dart.js',
  'prime': '/sample_js_workers/prime_worker.dart.js',
  'pi_digits': '/sample_js_workers/pi_digits_worker.dart.js',
  'rogue': '/sample_js_workers/rogue_worker.dart.js',
  'sample': '/sample_js_workers/sample_worker.dart.js',
  'echo': '/sample_js_workers/echo_worker.dart.js'
};

void main() async {
  final logger = Logger(querySelector('#output') as DivElement);

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
  });
  logHeader.append(clearLink);

  final buttonBar = querySelector('#button-bar')!;

  final sampleWorkerButton =
      buttonBar.append(ButtonElement()..text = 'Run SampleWorker tests')
          as ButtonElement;
  final sampleWorkerPoolButton =
      buttonBar.append(ButtonElement()..text = 'Run SampleWorker pool tests')
          as ButtonElement;
  final primeWorkerButton = buttonBar
      .append(ButtonElement()..text = 'Run PrimeWorker tests') as ButtonElement;
  final rogueWorkerButton = buttonBar
      .append(ButtonElement()..text = 'Run RogueWorker tests') as ButtonElement;

  final allButton = buttonBar.append(ButtonElement()..text = 'Run all tests')
      as ButtonElement;

  void run(Map<String, UnitTest> tests) async {
    var total = 0;
    var green = 0;
    var red = 0;
    logger.log('');

    void log(String message) {
      if (red == 0) {
        logger.log('<b><span class="green">+$green</span> - $message</b>');
      } else if (green == 0) {
        logger.log('<b><span class="red">-$red</span> - $message</b>');
      } else {
        logger.log(
            '<b><span class="green">+$green</span> <span class="red">-$red</span> - $message</b>');
      }
    }

    sampleWorkerButton.disabled = true;
    sampleWorkerPoolButton.disabled = true;
    primeWorkerButton.disabled = true;
    rogueWorkerButton.disabled = true;
    allButton.disabled = true;
    for (var entry in tests.entries) {
      total++;
      log(entry.key);
      var success = false;
      try {
        success = await entry.value(logger, _entryPoints);
      } on TestFailedException catch (e) {
        logger.log('<b><span class="red">TEST FAILED: ${e.message}</span></b>');
      } catch (e) {
        logger.log(
            '<b><span class="red">TEST FAILED: ${e.runtimeType} exception: $e</span></b>');
      }
      if (success) {
        green++;
      } else {
        red++;
      }
      log('${entry.key}: ${success ? 'PASS' : 'FAILED'}');
      logger.log('');
    }
    if (green == total) {
      log('<span class="green">100% PASS</span></b>');
    } else {
      logger.log(
          '<span class="green">${((green * 100.0) / total).toStringAsFixed(2)}% PASS</span> - <span class="red">$red FAILED</span></b>');
    }
    sampleWorkerButton.disabled = false;
    sampleWorkerPoolButton.disabled = false;
    primeWorkerButton.disabled = false;
    rogueWorkerButton.disabled = false;
    allButton.disabled = false;
  }

  final allTests = <String, UnitTest>{}
    ..addEntries(sampleWorkerTests.entries)
    ..addEntries(sampleWorkerPoolTests.entries)
    ..addEntries(primeWorkerTests.entries)
    ..addEntries(rogueWorkerTests.entries);

  sampleWorkerButton.onClick.listen((MouseEvent m) => run(sampleWorkerTests));
  sampleWorkerPoolButton.onClick
      .listen((MouseEvent m) => run(sampleWorkerPoolTests));
  primeWorkerButton.onClick.listen((MouseEvent m) => run(primeWorkerTests));
  rogueWorkerButton.onClick.listen((MouseEvent m) => run(rogueWorkerTests));
  allButton.onClick.listen((MouseEvent m) => run(allTests));

  logger.log('Ready');
}
