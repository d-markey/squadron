import 'dart:async';
import 'dart:convert';
import 'dart:html' as web;
import 'dart:js' as js;
import 'dart:typed_data';

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/web/_uri_checker.dart';

import '../../classes/test_entry_points.dart';

const platform = SquadronPlatformType.js;
String platformName = web.window.navigator.userAgent;

final hasImageCodecs = js.context.callMethod('eval', [
  'typeof ImageDecoder > "u" ? !1 : navigator.vendor==="Google Inc."||navigator.agent==="Edg/"'
]) as bool;

final hasChromiumBreakIterators = js.context.callMethod('eval', [
  'typeof Intl.v8BreakIterator < "u" && typeof Intl.Segmenter < "u"'
]) as bool;

final supportsWasmGc = (() {
  final res = js.context.callMethod('eval', ['WebAssembly.validate']);
  if (res is! js.JsFunction) return false;
  final s =
      Uint8List.fromList([0, 97, 115, 109, 1, 0, 0, 0, 1, 5, 1, 95, 1, 120, 0]);
  return res.apply([s]) == true;
})();

final isCrossOriginIsolated =
    js.context.callMethod('eval', ['window.crossOriginIsolated']) as bool;

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

    native = Squadron.uri('$root/native_worker.js');

    notAWorker = Squadron.uri('$root/not_a_worker.dart.$ext');
    echo = Squadron.uri('$root/echo_worker.dart.$ext');
    cache = Squadron.uri('$root/cache_worker.dart.$ext');
    installable = Squadron.uri('$root/installable_worker.dart.$ext');
    issues = Squadron.uri('$root/issues_worker.dart.$ext');
    local = Squadron.uri('$root/local_client_worker.dart.$ext');
    prime = Squadron.uri('$root/prime_worker.dart.$ext');
    test = Squadron.uri('$root/test_worker.dart.$ext');

    inMemory = Uri.parse(
        'data:application/javascript;base64,${base64Encode(utf8.encode('''
onmessage = (e) => { postMessage(`ECHO "\${e.data}"`); };
'''))}');

    // await _checkWebWorkers(defined);

    missingWorker = Squadron.uri('$root/missing_worker.dart.$ext');
  }
}

void _fail(String message) {
  web.window.console.error(message);
  throw Exception(message);
}

// ignore: unused_element
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
