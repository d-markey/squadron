import 'package:meta/meta.dart';

import '../../converters/cast_converter.dart';
import '../../converters/converter.dart';
import '../../squadron_platform_type.dart';

Converter getPlatformConverter() => CastConverter.instance;

SquadronPlatformType getPlatformType() => SquadronPlatformType.unknown;

Uri mapUrl(String url) => Uri.parse(url);

@internal
bool isSameInstance(Object a, Object b) => identical(a, b);
