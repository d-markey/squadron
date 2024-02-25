import 'dart:isolate';

String get threadId =>
    '0x${Isolate.current.hashCode.toRadixString(8).padLeft(8, '0')}';
