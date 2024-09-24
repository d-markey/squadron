import '../../converters/cast_converter.dart';
import '../../converters/converter.dart';
import '../../converters/num_converter.dart';
import '../../squadron_platform_type.dart';
import '_patch.dart';

Converter getPlatformConverter() => (1.toDouble() is int)
    ? CastConverter.instance // JavaScript
    : NumConverter.instance; // Web Assembly

SquadronPlatformType getPlatformType() => (1.toDouble() is int)
    ? SquadronPlatformType.js // JavaScript
    : SquadronPlatformType.wasm; // Web Assembly

Uri mapUrl(String url) {
  if (url.startsWith('~')) {
    final root = getHome();
    if (root != null) {
      url = '$root${url.substring(1)}';
    }
  }
  return Uri.parse(url);
}
