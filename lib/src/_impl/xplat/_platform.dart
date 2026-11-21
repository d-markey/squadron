import 'package:meta/meta.dart';

import '../../converters/cast_converter.dart';
import '../../squadron_platform_type.dart';
import '../web/_platform.dart' if (dart.library.io) '../native/_platform.dart'
    as impl;

String get threadId => impl.threadId;

int get numberOfProcessors => impl.numberOfProcessors;

const platformType = SquadronPlatformType.unknown;

const platformConverter = CastConverter.instance;

final osType = SquadronOSType.unknown;

@internal
bool isSameInstance(Object a, Object b) => identical(a, b);
