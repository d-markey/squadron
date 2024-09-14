import '../../converters/cast_converter.dart';
import '../../squadron_platform_type.dart';

CastConverter getPlatformConverter() => CastConverter.instance;

SquadronPlatformType getPlatformType() => SquadronPlatformType.unknown;

Uri mapUrl(String url) => Uri.parse(url);
