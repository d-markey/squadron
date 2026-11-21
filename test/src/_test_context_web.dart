import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/web/_uri_checker.dart';
import 'package:squadron/src/_impl/web/_web_entry_point_uri.dart';
import 'package:web/web.dart' as web;

import 'test_entry_points.dart';

final platform = Squadron.platformType;
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
  Future<void> set(String? root, SquadronPlatformType platform) async {
    root ??= '';
    final String ext;
    switch (platform) {
      case SquadronPlatformType.js:
        root = '$root/workers/js';
        ext = 'js';
        break;
      case SquadronPlatformType.wasm:
        root = '$root/workers/wasm';
        ext = 'wasm';
        break;
      default:
        throw UnsupportedError('Unsupported platform $platform');
    }

    native = WebEntryPoint(mapUrl('$root/native_worker.js'));

    notAWorker = WebEntryPoint(mapUrl('$root/not_a_worker.dart.$ext'));
    echo = WebEntryPoint(mapUrl('$root/echo_worker.dart.$ext?v=1'));
    cache = WebEntryPoint(mapUrl('$root/cache_worker.dart.$ext?v=1'));
    installable = WebEntryPoint(mapUrl('$root/installable_worker.dart.$ext'));
    issues = WebEntryPoint(mapUrl('$root/issues_worker.dart.$ext'));
    local = WebEntryPoint(mapUrl('$root/local_client_worker.dart.$ext'));
    prime = WebEntryPoint(mapUrl('$root/prime_worker.dart.$ext'));
    log = WebEntryPoint(mapUrl('$root/log_worker.dart.$ext?v=1'));
    streaming = WebEntryPoint(mapUrl('$root/streaming_worker.dart.$ext'));
    test = WebEntryPoint(mapUrl('$root/test_worker.dart.$ext'));
    person = WebEntryPoint(mapUrl('$root/person_worker.dart.$ext'));
    errors = WebEntryPoint(mapUrl('$root/error_worker.dart.$ext'));

    final js = 'onmessage = (e) => { postMessage(`ECHO "\${e.data}"`); };';
    inMemory = WebEntryPoint(
      'data:application/javascript;base64,${base64Encode(utf8.encode(js))}',
    );

    await _checkWebWorkers(defined.cast<WebEntryPoint>());

    missingWorker = WebEntryPoint(mapUrl('$root/missing_worker.dart.$ext'));
  }
}

Future _checkWebWorkers(Iterable<WebEntryPoint> workerUrls) async {
  final messages = <String>[];

  for (var workerUrl in workerUrls
      .map((e) => Uri.parse(e.url))
      .where((u) => u.scheme != 'data')) {
    if (!await UriChecker.exists(workerUrl)) {
      web.console.error('Worker $workerUrl not found'.toJS);
      messages.add('Worker $workerUrl not found');
    }
  }

  if (messages.isNotEmpty) {
    throw Exception('''

============================================================================ 
Cannot run tests because some workers are missing.
Please ensure Web Workers have been compiled prior to running Browser tests.

${messages.join('\n')}
============================================================================ 

''');
  }
}
