import 'dart:async';

import 'package:squadron/squadron.dart';

import 'bitcoin_service.dart';

class BitcoinWorker extends Worker implements BitcoinService {
  BitcoinWorker(dynamic entryPoint, {String? id, List args = const []})
      : super(entryPoint, id: id, args: args);

  @override
  Future<double?> getRate(String currency) =>
      send(BitcoinService.rateCommand, [currency]);

  @override
  final Map<int, CommandHandler> operations = const {};
}
