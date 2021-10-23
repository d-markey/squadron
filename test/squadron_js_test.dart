@TestOn('browser')

import 'dart:html';

import 'package:test/test.dart';

import 'squadron_worker_pool_test_suite.dart';
import 'squadron_worker_test_suite.dart';

void main() async {
  print('Running browser tests on ${window.navigator.appVersion}...');

  final html = DomParser().parseFromString(
      await HttpRequest.getString(window.location.href), 'text/html');

  final workers = html.querySelectorAll('link[rel="x-dart-worker"]');

  var missingWorkers = <String>{};
  for (var worker in workers) {
    var path = worker.attributes['href'];
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
    print('Browser tests need JavaScript versions for Web Workers.');
    for (var path in missingWorkers) {
      if (path.endsWith('.dart')) {
        print('Worker $path does not exist');
      } else if (path.endsWith('.js')) {
        print(
            'Worker $path must be generated with: dart compile js ${path.substring(0, path.length - '.js'.length)} -o $path');
      } else {
        print('Worker $path is invalid; path must end with .dart or .js');
      }
    }
    throw Exception(
        'Cannot run tests because some workers are missing or invalid.');
  }

  group("Worker", () {
    workerTests();
  });

  group("Worker pool", () {
    poolTests();
  });
}

Future<bool> exists(String path) async {
  try {
    await HttpRequest.getString(path, onProgress: (event) {
      // continue
    });
    return true;
  } catch (e) {
    return false;
  }
}
