import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http show read;

import 'package:squadron/squadron_service.dart';

class BitcoinService implements WorkerService {
  Future<double?> getRate(String currency) async {
    final currentPrice = jsonDecode(await http
        .read(Uri.parse('https://api.coindesk.com/v1/bpi/currentprice.json')));
    final rate = currentPrice?['bpi']?[currency]?['rate_float'];
    return (rate is num) ? rate.toDouble() : null;
  }

  static const rateCommand = 1;

  @override
  late final Map<int, CommandHandler> operations = {
    BitcoinService.rateCommand: (r) => getRate(r.args[0]),
  };
}
