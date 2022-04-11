@TestOn('browser')

import 'dart:async';
import 'dart:html' as web;

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/memory_logger.dart';
import 'test_suites/cancellation_test_suite.dart';
import 'test_suites/issues_test_suite.dart';
import 'test_suites/local_worker_test_suite.dart';
import 'test_suites/logger_test_suite.dart';
import 'test_suites/web_worker_test_suite.dart';
import 'test_suites/worker_pool_test_suite.dart';
import 'test_suites/worker_test_suite.dart';
import 'worker_services/worker_entry_points.dart';

void main() async {
  await _checkWebWorkers(EntryPoints.entryPoints.cast<String>());

  group('BROWSER', () {
    print('Running browser tests on ${web.window.navigator.appVersion}...');

    final memoryLogger = MemoryLogger();

    setUp(() {
      Squadron.setId('workerTests');
      Squadron.logLevel = SquadronLogLevel.all;
      Squadron.logger = memoryLogger;
      memoryLogger.clear();
    });

    group('- Logger', () {
      loggerTests();
    });

    group("- Web Worker", () {
      webWorkerTests();
    });

    group("- Worker", () {
      workerTests();
    });

    group("- Worker pool", () {
      poolTests();

      group("- Cancellation", () {
        cancellationTests();
      });
    });

    group("- Local Worker", () {
      localWorkerTests();
    });

    group("- GitHub Issues", () {
      githubIssuesTests();
    });
  });
}

Future _checkWebWorkers(Iterable<String> workerUrls) async {
  if (!web.Worker.supported) {
    throw Exception('''

============================================================================ 
Web Workers are not supported on this platform
============================================================================ 
''');
  }

  final messages = <String>[];

  final html = web.DomParser().parseFromString(
      await web.HttpRequest.getString(web.window.location.href), 'text/html');

  final workerLinks = html.querySelectorAll('link[rel="x-web-worker"]');

  var workers = <String>{};
  for (var workerLink in workerLinks) {
    var path = workerLink.attributes['href'];
    if (path == null) {
      messages.add('href attribute is missing for ${workerLink.outerHtml}');
    } else if (!path.endsWith('.js')) {
      messages.add(
          'URLs for Web Worker $path must reference a JavaScript file ending with \'.js\'');
    } else if (!await exists(path)) {
      messages.add('Web Worker $path could not be found');
    } else if (!workerUrls.contains(path)) {
      messages.add('Web Worker $path is not used');
    } else {
      workers.add(path);
    }
  }

  for (var workerUrl in workerUrls) {
    if (!workers.contains(workerUrl)) {
      messages.add(
          'Worker $workerUrl is not referenced from the test HTML template file. It should be referenced with:\n   <link rel="x-web-worker" href="$workerUrl">');
    }
  }

  if (messages.isNotEmpty) {
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
    await web.HttpRequest.getString(path);
    return true;
  } catch (e) {
    return false;
  }
}
