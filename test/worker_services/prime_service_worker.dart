import 'dart:async';

import 'package:squadron/squadron.dart';

import 'prime_service.dart';

class PrimeWorker extends Worker implements PrimeService {
  PrimeWorker(dynamic entryPoint, {String? id, List args = const []})
      : super(entryPoint, id: id, args: args);

  @override
  Future<bool> isPrime(int n) => send<bool>(PrimeService.isPrimeCommand, [n]);

  @override
  Stream<int> getPrimes(int min, int max) =>
      stream<int>(PrimeService.getPrimesCommand, [min, max]);

  @override
  final Map<int, CommandHandler> operations = const {};
}

