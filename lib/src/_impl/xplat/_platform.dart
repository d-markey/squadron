import 'package:meta/meta.dart';

import '../../converters/cast_converter.dart';
import '../../converters/converter.dart';
import '../../exceptions/squadron_error.dart';
import '../../squadron_platform_type.dart';
import '_typedefs.dart';

Converter getPlatformConverter() => CastConverter.instance;

SquadronPlatformType getPlatformType() => SquadronPlatformType.unknown;

Uri mapUrl(String url) => Uri.parse(url);

@internal
void terminateThread(PlatformThread thread) =>
    throw SquadronErrorExt.create('Platform not supported');
