import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:squadron/squadron.dart';
import 'package:squadron/src/_impl/web/_uri_checker.dart';
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

    native = Squadron.uri('$root/native_worker.js');

    notAWorker = Squadron.uri('$root/not_a_worker.dart.$ext');
    echo = Squadron.uri('$root/echo_worker.dart.$ext');
    cache = Squadron.uri('$root/cache_worker.dart.$ext');
    installable = Squadron.uri('$root/installable_worker.dart.$ext');
    issues = Squadron.uri('$root/issues_worker.dart.$ext');
    local = Squadron.uri('$root/local_client_worker.dart.$ext');
    prime = Squadron.uri('$root/prime_worker.dart.$ext');
    log = Squadron.uri('$root/log_worker.dart.$ext');
    test = Squadron.uri('$root/test_worker.dart.$ext');
    errors = Squadron.uri('$root/error_worker.dart.$ext');

    inMemory = Uri.parse(
        'data:application/javascript;base64,${base64Encode(utf8.encode('''
onmessage = (e) => { postMessage(`ECHO "\${e.data}"`); };
'''))}');

    await _checkWebWorkers(defined.cast<Uri>());

    missingWorker = Squadron.uri('$root/missing_worker.dart.$ext');
  }
}

// ignore: unused_element
Future _checkWebWorkers(Iterable<Uri> workerUrls) async {
  final messages = <String>[];

  for (var workerUrl in workerUrls.where((u) => u.scheme != 'data')) {
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
