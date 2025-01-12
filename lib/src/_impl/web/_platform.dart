import '../../converters/cast_converter.dart';
import '../../converters/converter.dart';
import '../../converters/num_converter.dart';
import '../../squadron_platform_type.dart';
import '_patch.dart';

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
