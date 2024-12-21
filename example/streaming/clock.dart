import 'package:squadron/squadron.dart';

class Clock {
  Stream<int> infiniteClock({int periodInMs = 1000}) async* {
    final period = Duration(milliseconds: periodInMs);
    int n = 0;
    while (true) {
      n += 1;
      print('[$threadId] Sending  $n from service');
      yield n;
      await Future.delayed(period);
    }
  }
}

/// Use squadron_builder to generate the following code.
/// Manual implementation is discouraged.
///
/// See https://github.com/d-markey/squadron_builder/tree/main/example/streaming

class ClockWorkerService extends Clock implements WorkerService {
  @override
  late final operations = {
    $clockId: (WorkerRequest r) => infiniteClock(periodInMs: _toInt(r.args[0]))
  };

  static const $clockId = 1;
}

class ClockWorker extends Worker implements Clock {
  ClockWorker(super.entryPoint,
      {super.args, super.threadHook, super.exceptionManager});

  @override
  Stream<int> infiniteClock({int periodInMs = 1000}) => stream(
        ClockWorkerService.$clockId,
        args: [periodInMs],
      ).map(_toInt);
}

Cast<int> get _toInt => Squadron.converter.value<int>();

void startWorker(WorkerRequest command) => run(
      (_) => ClockWorkerService(),
      command,
    );
