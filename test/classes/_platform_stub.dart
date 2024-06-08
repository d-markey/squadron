import 'package:logger/logger.dart';

dynamic getUnsendable() => throw UnsupportedError('Unsupported platform');

dynamic getWorkerChannel(Logger? logger) =>
    throw UnsupportedError('Unsupported platform');

String get threadId => throw UnsupportedError('Unsupported platform');
