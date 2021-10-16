import 'dart:async';
import 'dart:html';

import 'package:squadron/squadron.dart';

import '../test/worker_services/sample_service.dart';
import 'sample_worker_js.dart';
import 'cache_worker_js.dart';
import 'prime_worker_js.dart';

extension Log on DivElement {
  void log(Stopwatch sw, String message, {bool replaceLastLine = false}) {
    if (message.isNotEmpty) {
      message = '[${sw.elapsed}] $message';
    }
    final lines = (innerHtml ?? '').split('<br>');
    if (lines.length == 1 && lines[0].isEmpty) {
      lines.clear();
    }
    if (replaceLastLine && lines.isNotEmpty) {
      lines[lines.length - 1] = message;
    } else {
      lines.add(message);
    }
    innerHtml = lines.join('<br>');
    scrollTo(0, 10000);
  }

  void clear() {
    innerHtml = '';
  }
}

void Function(String message, {bool replaceLastLine}) getLogger(
    Stopwatch sw, DivElement output) {
  return (String message, {bool replaceLastLine = false}) =>
      output.log(sw, message, replaceLastLine: replaceLastLine);
}

void main() async {
  final sw = Stopwatch()..start();
  final output = querySelector('#output') as DivElement;

  final logger = getLogger(sw, output);

  logger('Ready');
  logger('');

  final logHeader = querySelector('#log-header')!;
  final separator = Element.span();
  separator.text = ' - ';
  logHeader.append(separator);
  final clearLink = Element.a();
  clearLink.text = 'Clear';
  clearLink.attributes['href'] = '#';
  clearLink.onClick.listen((MouseEvent e) {
    output.clear();
    logger('Ready');
  });
  logHeader.append(clearLink);

  final buttonBar = querySelector('#button-bar')!;

  final sampleWorkerButton = ButtonElement();
  final primeWorkerButton = ButtonElement();

  sampleWorkerButton.text = 'Run SampleWorker tests';
  sampleWorkerButton.onClick.listen((MouseEvent m) {
    output.clear();
    sampleWorkerButton.disabled = true;
    primeWorkerButton.disabled = true;
    runSampleWorkerTests(logger).whenComplete(() {
      sampleWorkerButton.disabled = false;
      primeWorkerButton.disabled = false;
    });
  });
  buttonBar.append(sampleWorkerButton);

  primeWorkerButton.text = 'Run PrimeWorker tests';
  primeWorkerButton.onClick.listen((MouseEvent m) {
    output.clear();
    sampleWorkerButton.disabled = true;
    primeWorkerButton.disabled = true;
    runPrimeWorkerTests(logger).whenComplete(() {
      sampleWorkerButton.disabled = false;
      primeWorkerButton.disabled = false;
    });
  });
  buttonBar.append(primeWorkerButton);
}

Future runSampleWorkerTests(
    void Function(String message, {bool replaceLastLine}) log) async {
  final w = SampleService();

  const sampleTaskDuration = 500;
  const taskCount = 10;

  final workerFutures = <Future>[];
  for (var i = 1; i <= taskCount; i++) {
    workerFutures.add(Future(() => w.cpu(milliseconds: sampleTaskDuration))
        .then((value) => log('Worker CPU task #$i completed')));
    workerFutures.add(w
        .io(milliseconds: sampleTaskDuration)
        .then((value) => log('Worker I/O task #$i completed')));
  }
  await Future.wait(workerFutures);

  log('');

  final pool = WorkerPool<SampleWorker>(() => createJsSampleWorker(),
      minWorkers: 1, maxWorkers: 4, maxParallel: 3);
  await pool.start();

  void logPoolStats(WorkerPool pool) {
    log('Pool stats:');
    log('Current workload: ${pool.workload}');
    log('Pending workload: ${pool.pendingWorkload}');
    for (var stat in pool.stats) {
      log(stat.toString());
    }
  }

  final poolMonitor = Timer.periodic(
      Duration(milliseconds: 500), (timer) => logPoolStats(pool));
  final poolFutures = <Future>[];
  for (var i = 1; i <= taskCount; i++) {
    poolFutures.add(pool
        .compute((worker) => worker.cpu(milliseconds: sampleTaskDuration))
        .then((value) => log('Pool CPU task #$i completed')));
    poolFutures.add(pool
        .compute((worker) => worker.io(milliseconds: sampleTaskDuration))
        .then((value) => log('Pool I/O task #$i completed')));
  }
  await Future.wait(poolFutures);
  poolMonitor.cancel();

  log('');
  logPoolStats(pool);

  log('');
  log('Cleaning up...');
  pool.stop();
  log('SampleWorker tests done.');
}

Future runPrimeWorkerTests(
    void Function(String message, {bool replaceLastLine}) log) async {
  final count = 1000;
  final first = 123456789; // first number must be odd
  final last = first + count - 1;

  final primeWorkerWithoutCache = createJsPrimeWorker();
  await primeWorkerWithoutCache.start();

  log('Prime test, range $first-$last - stream (no cache)');
  final streamSw = Stopwatch()..start();
  await for (var n in primeWorkerWithoutCache.getPrimes(first, last)) {
    log('$n is prime');
  }
  streamSw.stop();
  log('Stream version took ${streamSw.elapsed}');

  log('');

  log('Prime test, range $first-$last - loop (no cache)');
  final loopSw = Stopwatch()..start();
  for (var i = first; i <= last; i += 2) {
    if (await primeWorkerWithoutCache.isPrime(i)) {
      log('$i is prime');
    }
  }
  loopSw.stop();
  log('Loop version took ${loopSw.elapsed}');

  log('');

  final cacheWorker = createJsCacheWorker();
  await cacheWorker.start();

  final primeWorkerWithCache = createJsPrimeWorker(cacheWorker);
  await primeWorkerWithCache.start();

  log('Prime test, range $first-$last - stream (cache is empty)');
  streamSw.reset();
  streamSw.start();
  await for (var n in primeWorkerWithCache.getPrimes(first, last)) {
    log('$n is prime');
  }
  streamSw.stop();
  log('Stream version took ${streamSw.elapsed}');

  log('');
  var stats = await cacheWorker.getStats();
  log('Cache stats: $stats');
  log('');

  log('Prime test, range $first-$last - loop (cache contains ${stats.size} items)');
  loopSw.reset();
  loopSw.start();
  for (var i = first; i <= last; i += 2) {
    if (await primeWorkerWithCache.isPrime(i)) {
      log('$i is prime');
    }
  }
  loopSw.stop();
  log('Loop version took ${loopSw.elapsed}');

  log('');
  stats = await cacheWorker.getStats();
  log('Cache stats: $stats');

  log('PrimeWorker tests done.');
}

Future pause(
    void Function(String message, {bool replaceLastLine}) log, String message,
    {required int seconds}) async {
  final waitTime = Duration(seconds: seconds);
  final timerPeriod = Duration(milliseconds: 100);
  final sw = Stopwatch();
  final timer = Timer.periodic(timerPeriod, (timer) {
    final remaining = Duration(
        microseconds: waitTime.inMicroseconds - sw.elapsedMicroseconds);
    log(message.replaceAll('@countdown', remaining.toString()),
        replaceLastLine: sw.isRunning);
    sw.start();
  });
  await Future.delayed(waitTime);
  timer.cancel();
}
