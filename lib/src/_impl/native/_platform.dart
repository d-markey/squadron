import 'dart:isolate';

import '../../converters/cast_converter.dart';
import '../../converters/converter.dart';
import '../../squadron_platform_type.dart';
import '_typedefs.dart';

Converter getPlatformConverter() => CastConverter.instance;

SquadronPlatformType getPlatformType() => SquadronPlatformType.vm;

Uri mapUrl(String url) => Uri.parse(url);

void terminate(PlatformThread thread) {
  thread.kill(priority: Isolate.immediate);
}
