import 'dart:async';
import 'dart:convert';

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/wasm/_uri_checker.dart';
import 'package:web/web.dart' as web;

import '../classes/test_entry_points.dart';
import '../classes/test_platform.dart';

const platform = TestPlatform.wasm;
String platformName = '${web.window.navigator.userAgent} (wasm)';

bool _set = false;

Future<void> setEntryPoints(
    String root, TestPlatform platform, TestEntryPoints entryPoints) async {
  print('Test context platform = $platform');

  root = (platform == TestPlatform.wasm)
      ? '${root}sample_wasm_workers'
      : ((platform == TestPlatform.js)
          ? '${root}sample_js_workers'
          : throw UnsupportedError('Unsupported platform $platform'));

  if (!_set) {
    _set = true;
    root = '${root}sample_wasm_workers';

    entryPoints.native = '$root/native_worker.js';

    entryPoints.echo = '$root/echo_worker.dart.js';

    entryPoints.cache = '$root/cache_worker.dart.js';
    entryPoints.installable = '$root/installable_worker.dart.js';
    entryPoints.issues = '$root/issues_worker.dart.js';
    entryPoints.local = '$root/local_client_worker.dart.js';
    entryPoints.prime = '$root/prime_worker.dart.js';

    entryPoints.test = '$root/test_worker.dart.js';

    await _checkWebWorkers(entryPoints.defined);

    entryPoints.inMemory =
        'data:application/javascript;base64,${base64Encode(utf8.encode('''onmessage = (e) => {
  console.log("Message received from main script");
  const workerResult = `ECHO "\${e.data}"`;
  console.log("Posting message back to main script");
  postMessage(workerResult);
};'''))}';
  }
}

Future _checkWebWorkers(Iterable<EntryPoint> workerUrls) async {
  final messages = <String>[];

  // final resp = await http.get(Uri.parse(web.window.location.href));
  // final html = web.DOMParser().parseFromString(resp.body, 'text/html');

  // print('Checking ${html.documentElement!.innerHTML}');

  final workerLinks = web.document.querySelectorAll('link[rel="x-web-worker"]');

  final count = workerLinks.length;

  for (var i = 0; i < count; i++) {
    final workerLink = workerLinks.item(i) as web.Element;
    print('Checking $workerLink');
  }

  var workers = <EntryPoint>{};
  for (var i = 0; i < count; i++) {
    final workerLink = workerLinks.item(i) as web.Element;
    var path = workerLink.attributes.getNamedItem('href')?.value;
    if (path == null) {
      messages.add('href attribute is missing for ${workerLink.outerHTML}');
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
    print('''

============================================================================ 
Cannot run tests because some workers are missing or invalid.
Please ensure Web Workers have been compiled prior to running Browser tests.

${messages.join('\n')}
============================================================================ 
''');
  }
}
