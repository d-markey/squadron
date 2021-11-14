import 'dart:async';

import 'package:squadron/squadron.dart';

import 'pi_digits_service.dart';

class PiDigitsWorker extends Worker implements PiDigitsService {
  PiDigitsWorker(dynamic entryPoint, {String? id, List args = const []})
      : super(entryPoint, id: id, args: args);

  @override
  Future<int> getNth(int n) => send(PiDigitsService.getNthCommand, [n]);

  @override
  Stream<int> getNDigits(int start, int n) =>
      stream(PiDigitsService.getNDigitsCommand, [start, n]);

  @override
  final Map<int, CommandHandler> operations = const {};
}
