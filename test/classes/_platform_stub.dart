import 'package:logger/logger.dart';

// ignore: unused_element
final _ = (() {
  print('Imported _platform_stub.dart');
})();

dynamic getUnsendable() => throw UnsupportedError('Unsupported platform');

dynamic getWorkerChannel(Logger? logger) =>
    throw UnsupportedError('Unsupported platform');

String get threadId => throw UnsupportedError('Unsupported platform');
