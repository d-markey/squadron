import 'dart:async';

import 'package:cancelation_token/cancelation_token.dart';
import 'package:squadron/src/_impl/xplat/_cancelable_runner.dart';

import 'ext.dart';

final sw = Stopwatch()..start();

void fireAndForget(int n, CancelationToken? token) async {
  await Future.delayed(Duration(milliseconds: 1000));
  print('[${sw.elapsed}] F&F #$n (${token.status})');
}

Future<int> process({required bool withError, CancelationToken? token}) async {
  print('[${sw.elapsed}] PROCESS STARTED (${token.status})');
  for (var i = 0; i < 5; i++) {
    await Future.delayed(Duration(milliseconds: 500));
    print('[${sw.elapsed}] STEP $i (${token.status})');
    if (withError && i % 3 == 2) {
      print('[${sw.elapsed}] THROW ERROR (${token.status})');
      throw Exception('Error! (${token.status})');
    }
    fireAndForget(i, token);
  }
  print('[${sw.elapsed}] PROCESS DONE (${token.status})');
  return 1;
}

void main() async {
  final withErrors = true;
  final cancelable = CancelableToken();

  Timer? timer;
  try {
    timer = Timer(Duration(milliseconds: 2200), () {
      cancelable.cancel();
      print('[${sw.elapsed}] CANCEL (${cancelable.status})');
    });

    final data = await run(
      () => process(withError: withErrors, token: cancelable),
      cancelable,
    );

    print('[${sw.elapsed}] SUCCESS (${cancelable.status}): data = $data');
  } on CanceledException catch (ex) {
    print('[${sw.elapsed}] CANCELED (${cancelable.status}): $ex');
  } catch (ex, st) {
    print('[${sw.elapsed}] FAIL (${cancelable.status}): $ex -> $st');
  } finally {
    timer?.cancel();
  }

  print('[${sw.elapsed}] DONE (${cancelable.status})');
}
