import '../../converters/converter.dart';
import '../../converters/direct_cast_converter.dart';
import '../../squadron_platform_type.dart';

Converter getPlatformConverter() => DirectCastConverter.instance;

SquadronPlatformType getPlatformType() => SquadronPlatformType.vm;

Uri mapUrl(String url) => Uri.parse(url);
