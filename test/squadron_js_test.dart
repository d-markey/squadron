@TestOn('browser')

import 'dart:async';
import 'dart:html' as browser;

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/memory_logger.dart';
import 'test_suites/cancellation_test_suite.dart';
import 'test_suites/local_worker_test_suite.dart';
import 'test_suites/logger_test_suite.dart';
import 'test_suites/web_worker_test_suite.dart';
import 'test_suites/worker_pool_test_suite.dart';
import 'test_suites/worker_test_suite.dart';

void main() async {
  await _checkWebWorkers();

  group('BROWSER', () {
    print('Running browser tests on ${browser.window.navigator.appVersion}...');

    final memoryLogger = MemoryLogger();

    setUp(() {
      Squadron.setId('workerTests');
      Squadron.logLevel = SquadronLogLevel.ALL;
      Squadron.logger = memoryLogger;
      memoryLogger.clear();
    });

    group('Logger - ', () {
      loggerTests();
    });

    group("Web Worker - ", () {
      webWorkerTests();
    });

    group("Worker - ", () {
      workerTests();
    });

    group("Local Worker - ", () {
      localWorkerTests();
    });

    group("Worker pool - ", () {
      poolTests();

      group("Cancellation - ", () {
        cancellationTests();
      });
    });
  });
}

Future _checkWebWorkers() async {
  if (!browser.Worker.supported) {
    throw Exception('''

============================================================================ 
Web Workers are not supported on this platform
============================================================================ 
''');
  }

  final html = browser.DomParser().parseFromString(
      await browser.HttpRequest.getString(browser.window.location.href),
      'text/html');

  final workerLinks = html.querySelectorAll('link[rel="x-dart-worker"]');

  var missingWorkers = <String>{};
  for (var workerLink in workerLinks) {
    var path = workerLink.attributes['href'];
    if (path != null) {
      String? dart = path;
      if (dart.endsWith('.js')) {
        dart = dart.substring(0, dart.length - '.js'.length);
      }
      if (!dart.endsWith('.dart')) {
        dart = null;
      }
      String? js = path;
      if (!js.endsWith('.js')) {
        if (js.endsWith('.dart')) {
          js += '.js';
        } else {
          js = null;
        }
      }

      if (dart != null && !await exists(dart)) {
        missingWorkers.add(dart);
      } else if (js != null && !await exists(js)) {
        missingWorkers.add(js);
      } else if (dart == null && js == null) {
        missingWorkers.add(path);
      }
    }
  }

  if (missingWorkers.isNotEmpty) {
    final messages = <String>[];
    messages.add('Browser tests need JavaScript versions for Web Workers.');
    for (var path in missingWorkers) {
      if (path.endsWith('.dart')) {
        messages.add('Worker $path does not exist');
      } else if (path.endsWith('.js')) {
        messages.add(
            'Worker $path must be generated with:\n   dart compile js ${path.substring(0, path.length - '.js'.length)} -o $path');
      } else {
        messages
            .add('Worker $path is invalid; path must end with .dart or .js');
      }
    }

    throw Exception('''

============================================================================ 
Cannot run tests because some workers are missing or invalid.
Please ensure Web Workers have been compiled prior to running Browser tests.

${messages.join('\n')}
============================================================================ 
''');
  }
}

Future<bool> exists(String path) async {
  try {
    await browser.HttpRequest.getString(path, onProgress: (event) {
      // continue
    });
    return true;
  } catch (e) {
    return false;
  }
}
