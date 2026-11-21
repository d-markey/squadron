import 'dart:io';

Future<void> flush(Object o) async {
  if (o is IOSink) {
    await o.flush();
  }
}
