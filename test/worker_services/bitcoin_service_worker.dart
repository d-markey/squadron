import 'dart:async';

import 'package:squadron/squadron.dart';

import 'bitcoin_service.dart';

class BitcoinWorker extends Worker implements BitcoinService {
  BitcoinWorker(dynamic entryPoint) : super(entryPoint);

  @override
  Future<double?> getRate(String currency) =>
      send(BitcoinService.rateCommand, [currency]);
}
