import 'dart:async';
import 'dart:convert';
import 'dart:html' as web;

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/web/_uri_checker.dart';

import '../../classes/test_entry_points.dart';
import '../../classes/test_platform.dart';

const platform = TestPlatform.js;
String platformName = web.window.navigator.userAgent;

extension TestEntryPointsExt on TestEntryPoints {
  Future<void> set(String root, TestPlatform platform) async {
    String ext;
    switch (platform) {
      case TestPlatform.js:
        root = '${root}workers/js';
        ext = 'js';
        break;
      case TestPlatform.wasm:
        root = '${root}workers/wasm';
        ext = 'unopt.wasm';
        break;
      default:
        throw UnsupportedError('Unsupported platform $platform');
    }

    native = Uri.parse('$root/native_worker.js');

    notAWorker = Uri.parse('$root/not_a_worker.dart.$ext');
    echo = Uri.parse('$root/echo_worker.dart.$ext');
    cache = Uri.parse('$root/cache_worker.dart.$ext');
    installable = Uri.parse('$root/installable_worker.dart.$ext');
    issues = Uri.parse('$root/issues_worker.dart.$ext');
    local = Uri.parse('$root/local_client_worker.dart.$ext');
    prime = Uri.parse('$root/prime_worker.dart.$ext');
    test = Uri.parse('$root/test_worker.dart.$ext');

    inMemory = Uri.parse(
        'data:application/javascript;base64,${base64Encode(utf8.encode('''
onmessage = (e) => { postMessage(`ECHO "\${e.data}"`); };
'''))}');

    // await _checkWebWorkers(defined);

    missingWorker = Uri.parse('$root/missing_worker.dart.$ext');
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

  var workers = <Uri>{};
  for (var workerLink in workerLinks) {
    final path = workerLink.attributes['href'];
    final uri = Uri.parse(path ?? '/').normalizePath();
    final fileName = uri.pathSegments.last;
    if (path == null) {
      messages.add('href attribute is missing for ${workerLink.outerHtml}');
    } else if (!fileName.endsWith('.js') &&
        !fileName.endsWith('.mjs') &&
        !fileName.endsWith('.wasm')) {
      messages.add(
          'URLs for Web Worker $path must reference a JavaScript file ending with \'.js\' or a WebAssembly file ending with \'.wasm\'');
    } else if (!await UriChecker.exists(uri)) {
      messages.add('Web Worker $path could not be found');
    } else if (workerUrls
        .every((u) => u.normalizePath().toString() != uri.toString())) {
      messages.add('Web Worker $path is not used');
    } else {
      workers.add(uri);
    }
  }

  for (var workerUrl in workerUrls.where((u) => u.scheme != 'data')) {
    if (workers
        .every((u) => u.toString() != workerUrl.normalizePath().toString())) {
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
