import 'dart:async';

import 'package:squadron/squadron.dart';

import 'hello_world_worker.dart';
import 'hello_world_worker_vm_entrypoint.dart';

void main() async {
  final sw = Stopwatch()..start();

  void $log(Object event) => print('[${sw.elapsed}] $event');

  $log('Program running in main thread $threadId');

  final worker = HelloWorldWorker(start);
  await worker.start();

  // kill in 3.5 seconds
  Future.delayed(Duration(milliseconds: 3500), () {
    $log('Kill now!');
    worker.terminate();
  });

  $log('Say hello to Alice...');
  // display after 2 seconds if worker is still alive
  // should not throw because worker termination has not happened yet
  $log(await worker.sayHello('Alice', delayInSec: 2, echo: true));

  try {
    $log('Say hello to Bob...');
    // display after another 2 seconds if worker is still alive
    // will throw because of worker termination at 3.5 seconds
    $log(await worker.sayHello('Bob', delayInSec: 2, echo: true));
  } on TaskTerminatedException catch (ex) {
    $log(
        'Could not say hello to Bob, because the worker was terminated: ${ex.runtimeType}: "${ex.message}"');
  }

  $log('Making sure the worker will never say hello to Bob...');
  await Future.delayed(Duration(seconds: 5));
  $log('Done!');
}
