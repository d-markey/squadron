import 'expect.dart';
import '../test/worker_services/prime_service_worker.dart';
import '../test/worker_services/cache_service_worker.dart';
import 'logger.dart';

final primeWorkerTests = {
  'Primes - no cache': testPrimesWithoutCache,
  'Primes - with cache': testPrimesWithCache
};

final count = 1000;
final first = 123456789; // first number must be odd
final last = first + count - 1;

Future<bool> testPrimesWithoutCache(
    Logger logger, Map<String, String> entryPoints) async {
  final primeWorkerWithoutCache = PrimeWorker(entryPoints['prime']);
  await primeWorkerWithoutCache.start();

  logger.log('Prime test, range $first-$last - stream (no cache)...');
  final streamSw = Stopwatch()..start();
  var streamSum = 0;
  await for (var n in primeWorkerWithoutCache.getPrimes(first, last)) {
    streamSum += n;
    //logger.log('$n is prime');
  }
  streamSw.stop();
  logger.log(
      'Prime test, range $first-$last - stream (no cache)... completed in ${streamSw.elapsed}',
      replaceLastLine: true);

  logger.log('Prime test, range $first-$last - loop (no cache)...');
  final loopSw = Stopwatch()..start();
  var loopSum = 0;
  for (var i = first; i <= last; i += 2) {
    if (await primeWorkerWithoutCache.isPrime(i)) {
      loopSum += i;
      // logger.log('$i is prime');
    }
  }
  loopSw.stop();
  logger.log(
      'Prime test, range $first-$last - loop (no cache)... completed in ${loopSw.elapsed}',
      replaceLastLine: true);

  expect(loopSum == streamSum, 'loop and stream sums mst be equal');

  primeWorkerWithoutCache.stop();

  return true;
}

Future<bool> testPrimesWithCache(
    Logger logger, Map<String, String> entryPoints) async {
  final cacheWorker = CacheWorker(entryPoints['cache']);
  await cacheWorker.start();

  final primeWorkerWithCache =
      PrimeWorker(entryPoints['prime'], cacheWorker.channel);
  await primeWorkerWithCache.start();

  logger.log('Prime test, range $first-$last - stream (cache is empty)...');
  final streamSw = Stopwatch()..start();
  var streamSum = 0;
  await for (var n in primeWorkerWithCache.getPrimes(first, last)) {
    streamSum += n;
    // logger.log('$n is prime');
  }
  streamSw.stop();
  logger.log(
      'Prime test, range $first-$last - stream (cache is empty)... completed in ${streamSw.elapsed}',
      replaceLastLine: true);

  var stats = await cacheWorker.getStats();
  expect(stats.size == count ~/ 3, 'cache size must be ${count ~/ 3}');

  logger.log(
      'Prime test, range $first-$last - loop (cache contains ${stats.size} items)...');
  final loopSw = Stopwatch()..start();
  var loopSum = 0;
  for (var i = first; i <= last; i += 2) {
    if (await primeWorkerWithCache.isPrime(i)) {
      loopSum += i;
      // logger.log('$i is prime');
    }
  }
  loopSw.stop();
  logger.log(
      'Prime test, range $first-$last - loop (cache contains ${stats.size} items)... completed in ${loopSw.elapsed}',
      replaceLastLine: true);

  expect(loopSum == streamSum, 'loop and stream sums mst be equal');

  stats = await cacheWorker.getStats();
  expect(stats.size == count ~/ 2, 'cache size must be ${count ~/ 2}');

  cacheWorker.stop();
  primeWorkerWithCache.stop();

  return true;
}
