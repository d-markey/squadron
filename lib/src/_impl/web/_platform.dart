import '../../converters/cast_converter.dart';
import '../../converters/num_converter.dart';
import '../../squadron_platform_type.dart';

CastConverter getPlatformConverter() => (1.toDouble() is int)
    ? CastConverter.instance // JavaScript
    : NumConverter.instance; // Web Assembly

SquadronPlatformType getPlatformType() => (1.toDouble() is int)
    ? SquadronPlatformType.js // JavaScript
    : SquadronPlatformType.wasm;  // Web Assembly
