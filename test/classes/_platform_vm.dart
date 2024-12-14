import 'dart:io';
import 'dart:isolate';

dynamic getUnsendable() => ReceivePort();

void $log(String message) {
  stderr.writeln(message);
}
