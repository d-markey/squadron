import 'dart:async';
import 'dart:convert';
import 'dart:html' as web;

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/browser/_uri_checker.dart';

import '../classes/test_context.dart';

const platform = TestPlatform.js;
String platformName = web.window.navigator.userAgent;

bool _set = false;

extension EntryPointsExt on TestContext {
  Future<void> setEntryPoints(String root) async {
    if (!_set) {
      _set = true;
      root = '${root}sample_js_workers';

      entryPoints.inMemory =
          'data:application/javascript;base64,${base64Encode(utf8.encode('''onmessage = (e) => {
  console.log("Message received from main script");
  const workerResult = `ECHO "\${e.data}"`;
  console.log("Posting message back to main script");
  postMessage(workerResult);
};'''))}';

      entryPoints.echo = '$root/echo_worker.dart.js';
      entryPoints.native = '$root/native_worker.js';

      entryPoints.cache = '$root/cache_worker.dart.js';
      entryPoints.installable = '$root/installable_worker.dart.js';
      entryPoints.issues = '$root/issues_worker.dart.js';
      entryPoints.local = '$root/local_client_worker.dart.js';
      entryPoints.prime = '$root/prime_worker.dart.js';

      entryPoints.test = '$root/test_worker.dart.js';

      await _checkWebWorkers(definedEntryPoints);
    }
  }
}

Future _checkWebWorkers(Iterable<EntryPoint> workerUrls) async {
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

  var workers = <EntryPoint>{};
  for (var workerLink in workerLinks) {
    var path = workerLink.attributes['href'];
    if (path == null) {
      messages.add('href attribute is missing for ${workerLink.outerHtml}');
    } else if (!path.endsWith('.js')) {
      messages.add(
          'URLs for Web Worker $path must reference a JavaScript file ending with \'.js\'');
    } else if (!await UriChecker.exists(Uri.parse(path))) {
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
