import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';

import '../../converters/cast_converter.dart';
import '../../squadron_platform_type.dart';
import '../../utils.dart';

/// threadIDs may not be unique on VM...
final threadId = Isolate.current.hashCode.hex;

const platformConverter = CastConverter.instance;

const platformType = SquadronPlatformType.vm;

final osType = switch (Platform.operatingSystem) {
  'windows' => SquadronOSType.windows,
  'linux' => SquadronOSType.linux,
  'fuchsia' => SquadronOSType.fuchsia,
  'macos' => SquadronOSType.macos,
  'android' => SquadronOSType.android,
  'ios' => SquadronOSType.ios,
  _ => SquadronOSType.unknown
};

Uri mapUrl(String url) => Uri.parse(url);

@internal
bool isSameInstance(Object a, Object b) => identical(a, b);
