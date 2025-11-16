import 'dart:isolate';

import 'package:meta/meta.dart';

import '../../converters/cast_converter.dart';
import '../../converters/converter.dart';
import '../../squadron_platform_type.dart';
import '../../utils.dart';

/// threadIDs may not be unique on VM...
final String threadId = Isolate.current.hashCode.hex;

Converter getPlatformConverter() => CastConverter.instance;

SquadronPlatformType getPlatformType() => SquadronPlatformType.vm;

Uri mapUrl(String url) => Uri.parse(url).normalizePath();

@internal
bool isSameInstance(Object a, Object b) => identical(a, b);
