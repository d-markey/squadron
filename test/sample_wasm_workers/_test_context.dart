import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/xplat/_uri_checker.dart';
import 'package:web/web.dart' as web;

import '../classes/test_entry_points.dart';
import '../classes/test_platform.dart';

const platform = TestPlatform.wasm;
String platformName = '${web.window.navigator.userAgent} (wasm)';

extension TestEntryPointsExt on TestEntryPoints {
  Future<void> set(String root, TestPlatform platform) async {
    switch (platform) {
      case TestPlatform.js:
        root = '${root}sample_js_workers';
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
        root = '${root}sample_wasm_workers';
        final loader = '$root/squadron_wasm_worker_loader.js';
        native = '$root/native_worker.js';
        notAWorker = '$loader?worker=not_a_worker.dart';
        echo = '$loader?unopt&worker=echo_worker.dart';
        cache = '$loader?unopt&worker=cache_worker.dart';
        installable = '$loader?unopt&worker=installable_worker.dart';
        issues = '$loader?unopt&worker=issues_worker.dart';
        local = '$loader?unopt&worker=local_client_worker.dart';
        prime = '$loader?unopt&worker=prime_worker.dart';
        test = '$loader?unopt&worker=test_worker.dart';
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
  web.console.error(message.jsify());
  throw Exception(message);
}

Future _checkWebWorkers(Iterable<EntryPoint> workerUrls) async {
  final messages = <String>[];

  final workerLinks = web.document.querySelectorAll('link[rel="x-web-worker"]');

  final count = workerLinks.length;

  var workers = <EntryPoint>{};
  for (var i = 0; i < count; i++) {
    final workerLink = workerLinks.item(i) as web.Element;
    final path = workerLink.attributes.getNamedItem('href')?.value;
    final scriptUri = Uri.parse(path ?? '/');
    final scriptFileName = scriptUri.pathSegments.last;
    if (path == null) {
      messages.add('href attribute is missing for ${workerLink.outerHTML}');
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
