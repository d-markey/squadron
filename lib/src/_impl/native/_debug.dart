import 'dart:io';

import '_platform.dart';

void $log(String message) {
  stderr.writeln('[$threadId] $message');
}
