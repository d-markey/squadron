import 'dart:async';
import 'dart:convert';
import 'dart:html' as web;

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/xplat/_uri_checker.dart';

import '../../classes/test_entry_points.dart';
import '../../classes/test_platform.dart';

const platform = TestPlatform.js;
String platformName = '${web.window.navigator.userAgent} (js)';

extension TestEntryPointsExt on TestEntryPoints {
  Future<void> set(String root, TestPlatform platform) async {
    switch (platform) {
      case TestPlatform.js:
        root = '${root}workers/js';
        native = '$root/native_worker.js';
        notAWorker = '$root/not_a_worker.dart.js';
        echo = '$root/echo_worker.dart.js';
        cache = '$root/cache_worker.dart.js';
        installable = '$root/installable_worker.dart.js';
        issues = '$root/issues_worker.dart.js';
        local = '$root/local_client_worker.dart.js';
        prime = '$root/prime_worker.dart.js';
        test = '$root/test_worker.dart.js';
        break;
      case TestPlatform.wasm:
        final loader = 'wasm_loader.js';
        root = '${root}workers/wasm';
        native = '$root/native_worker.js';
        notAWorker = '$loader?worker=$root/not_a_worker.dart';
        echo = '$loader?unopt&worker=$root/echo_worker.dart';
        cache = '$loader?unopt&worker=$root/cache_worker.dart';
        installable = '$loader?unopt&worker=$root/installable_worker.dart';
        issues = '$loader?unopt&worker=$root/issues_worker.dart';
        local = '$loader?unopt&worker=$root/local_client_worker.dart';
        prime = '$loader?unopt&worker=$root/prime_worker.dart';
        test = '$loader?unopt&worker=$root/test_worker.dart';
        break;
      default:
        throw UnsupportedError('Unsupported platform $platform');
    }

    await _checkWebWorkers(defined);

    inMemory =
        'data:application/javascript;base64,${base64Encode(utf8.encode('''onmessage = (e) => {
  console.log("Message received from main script");
  const workerResult = `ECHO "\${e.data}"`;
  console.log("Posting message back to main script");
  postMessage(workerResult);
};'''))}';
  }
}

void _fail(String message) {
  web.window.console.error(message);
  throw Exception(message);
}

Future _checkWebWorkers(Iterable<EntryPoint> workerUrls) async {
  if (!web.Worker.supported) {
    _fail('''

============================================================================ 
Web Workers are not supported on this platform
============================================================================ 

''');
  }

  final messages = <String>[];

  final workerLinks = web.document.querySelectorAll('link[rel="x-web-worker"]');

  var workers = <EntryPoint>{};
  for (var workerLink in workerLinks) {
    final path = workerLink.attributes['href'];
    final scriptUri = Uri.parse(path ?? '/');
    final scriptFileName = scriptUri.pathSegments.last;
    if (path == null) {
      messages.add('href attribute is missing for ${workerLink.outerHtml}');
    } else if (!scriptFileName.endsWith('.js')) {
      messages.add(
          'URLs for Web Worker $path must reference a JavaScript file ending with \'.js\'');
    } else if (!await UriChecker.exists(scriptUri)) {
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
    _fail('''

============================================================================ 
Cannot run tests because some workers are missing or invalid.
Please ensure Web Workers have been compiled prior to running Browser tests.

${messages.join('\n')}
============================================================================ 

''');
  }
}
