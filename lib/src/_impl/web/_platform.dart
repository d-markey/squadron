import 'dart:js_interop';
import 'dart:math';

import 'package:meta/meta.dart';

import '../../converters/cast_converter.dart';
import '../../converters/converter.dart';
import '../../converters/num_converter.dart';
import '../../squadron_platform_type.dart';
import '../../utils.dart';
import '_patch.dart';

final _rnd = Random.secure();

int getRndHash() => _rnd.nextInt(0x100000000);

/// threadIDs may not be unique on Web...
final String threadId = _rnd.nextInt(0x100000000).hex;

const double _one = 1.0;
final _platformType = (_one is int)
    ? SquadronPlatformType.js // JavaScript
    : SquadronPlatformType.wasm; // Web Assembly

Converter getPlatformConverter() => _platformType.isJs
    ? CastConverter.instance // JavaScript
    : NumConverter.instance; // Web Assembly

SquadronPlatformType getPlatformType() => _platformType;

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
