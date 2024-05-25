import 'test_entry_points.dart';
import 'test_platform.dart';

TestPlatform get platform => throw UnsupportedError('Unsupported platform');
String get platformName => throw UnsupportedError('Unsupported platform');

Future<void> setEntryPoints(String root, TestEntryPoints entryPoints) async =>
    throw UnsupportedError('Unsupported platform');
