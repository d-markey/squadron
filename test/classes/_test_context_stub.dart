import 'test_context.dart' show TestPlatform;
import 'test_entry_points.dart';

TestPlatform get platform => throw UnsupportedError('Unsupported platform');
String get platformName => throw UnsupportedError('Unsupported platform');

bool get hasImageCodecs => throw UnsupportedError('Unsupported platform');

bool get hasChromiumBreakIterators =>
    throw UnsupportedError('Unsupported platform');

bool get supportsWasmGc => throw UnsupportedError('Unsupported platform');

bool get isCrossOriginIsolated =>
    throw UnsupportedError('Unsupported platform');

extension TestEntryPointsExt on TestEntryPoints {
  Future<void> set(String root, TestPlatform platform) async =>
      throw UnsupportedError('Unsupported platform');
}
