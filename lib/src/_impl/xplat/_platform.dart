import 'package:meta/meta.dart';

import '../../converters/cast_converter.dart';
import '../../converters/converter.dart';
import '../../squadron_platform_type.dart';
import '../web/_platform.dart' if (dart.library.io) '../native/_platform.dart'
    as impl;

String get threadId => impl.threadId;

Converter getPlatformConverter() => CastConverter.instance;

SquadronPlatformType getPlatformType() => SquadronPlatformType.unknown;

Uri mapUrl(String url) => Uri.parse(url);

@internal
bool isSameInstance(Object a, Object b) => identical(a, b);
