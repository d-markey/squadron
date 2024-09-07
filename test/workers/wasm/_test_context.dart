import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/web/_uri_checker.dart';
import 'package:web/web.dart' as web;

import '../../classes/test_entry_points.dart';

const platform = SquadronPlatformType.wasm;
String platformName = web.window.navigator.userAgent;

final hasImageCodecs = globalContext
    .callMethod(
        'eval'.toJS,
        'typeof ImageDecoder > "u" ? !1 : navigator.vendor==="Google Inc."||navigator.agent==="Edg/"'
            .toJS)
    .dartify() as bool;

final hasChromiumBreakIterators = globalContext
    .callMethod('eval'.toJS,
        'typeof Intl.v8BreakIterator < "u" && typeof Intl.Segmenter < "u"'.toJS)
    .dartify() as bool;

final supportsWasmGc = (() {
  final s =
      Uint8List.fromList([0, 97, 115, 109, 1, 0, 0, 0, 1, 5, 1, 95, 1, 120, 0]);
  return web.WebAssembly.validate(s.toJS);
})();

final isCrossOriginIsolated = web.window.crossOriginIsolated;

extension TestEntryPointsExt on TestEntryPoints {
  Future<void> set(String root, SquadronPlatformType platform) async {
    final String ext;
    switch (platform) {
      case SquadronPlatformType.js:
        root = '$root/workers/js';
        ext = 'js';
        break;
      case SquadronPlatformType.wasm:
        root = '$root/workers/wasm';
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
  web.console.error(message.jsify());
  throw Exception(message);
}

// ignore: unused_element
Future _checkWebWorkers(Iterable<EntryPoint> workerUrls) async {
  final messages = <String>[];

  final workerLinks = web.document.querySelectorAll('link[rel="x-web-worker"]');

  final count = workerLinks.length;

  var workers = <EntryPoint>{};
  for (var i = 0; i < count; i++) {
    final workerLink = workerLinks.item(i) as web.Element;
    final path = workerLink.attributes.getNamedItem('href')?.value;
    final uri = Uri.parse(path ?? '/');
    final fileName = uri.pathSegments.last;
    if (path == null) {
      messages.add('href attribute is missing for ${workerLink.outerHTML}');
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
