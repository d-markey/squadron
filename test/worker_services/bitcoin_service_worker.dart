import 'dart:async';

import 'package:squadron/squadron.dart';

import 'bitcoin_service.dart';
import 'worker_entry_points.dart';

class BitcoinWorker extends Worker implements BitcoinService {
  BitcoinWorker() : super(EntryPoints.bitcoin);

  @override
  Future<double?> getRate(String currency) =>
      send(BitcoinService.rateCommand, [currency]);
}
