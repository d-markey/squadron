import 'package:meta/meta.dart';

import '../../converters/converter.dart';
import '../../exceptions/squadron_error.dart';
import '../../squadron_platform_type.dart';

String get threadId => throw SquadronErrorImpl.create('Platform not supported');

Converter getPlatformConverter() =>
    throw SquadronErrorImpl.create('Platform not supported');

SquadronPlatformType getPlatformType() =>
    throw SquadronErrorImpl.create('Platform not supported');

Uri mapUrl(String url) =>
    throw SquadronErrorImpl.create('Platform not supported');

@internal
bool isSameInstance(Object a, Object b) =>
    throw SquadronErrorImpl.create('Platform not supported');
