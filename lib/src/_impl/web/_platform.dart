import 'dart:js_interop';
import 'dart:math';

import 'package:meta/meta.dart';

import '../../build_options.dart';
import '../../converters/cast_converter.dart';
import '../../converters/num_converter.dart';
import '../../squadron_platform_type.dart';
import '../../utils.dart';
import '_patch.dart';

final _rnd = Random.secure();
int getRandomHash() => _rnd.nextInt(0x100000000);

// threadIDs may not be unique on Web...
final threadId = getRandomHash().hex;

const platformType = BuildOptions.isWasm
    ? SquadronPlatformType.wasm // Web Assembly
    : SquadronPlatformType.js; // JavaScript

const platformConverter = BuildOptions.isWasm
    ? NumConverter.instance // Web Assembly
    : CastConverter.instance; // JavaScript

final osType = SquadronOSType.web;

Uri mapUrl(String url) {
  if (url.startsWith('~')) {
    final root = getRootUrl();
    if (root != null) {
      url = '$root${url.substring(1)}';
    }
  }
  return Uri.parse(url).normalizePath();
}

@internal
// ignore: invalid_runtime_check_with_js_interop_types
bool isSameInstance(Object a, Object b) => (a is JSObject)
    // ignore: invalid_runtime_check_with_js_interop_types
    ? ((b is JSObject) && $is(a, b))
    // ignore: invalid_runtime_check_with_js_interop_types
    : ((b is! JSObject) && identical(a, b));
