import 'package:squadron/squadron_service.dart';
import 'package:test/test.dart';

import 'memory_logger.dart';

void loggerTests() {
  final memoryLogger = MemoryLogger();

  final logLevels = {
    SquadronLogLevel.FINEST: 'FINEST',
    SquadronLogLevel.FINER: 'FINER',
    SquadronLogLevel.FINE: 'FINE',
    SquadronLogLevel.CONFIG: 'CONFIG',
    SquadronLogLevel.INFO: 'INFO',
    SquadronLogLevel.WARNING: 'WARNING',
    SquadronLogLevel.SEVERE: 'SEVERE',
    SquadronLogLevel.SHOUT: 'SHOUT',
  };

  setUp(() {
    memoryLogger.clear();
    Squadron.logger = memoryLogger;
    Squadron.logLevel = SquadronLogLevel.ALL;
  });

  test('Finest', () {
    for (var logLevel in logLevels.entries) {
      Squadron.logLevel = logLevel.key;
      Squadron.finest('Finest - ${logLevel.value}');
    }

    expect(memoryLogger.length, equals(1));
    expect(memoryLogger.contains('Finest - FINEST'), isTrue);
  });

  test('Finer', () {
    for (var logLevel in logLevels.entries) {
      Squadron.logLevel = logLevel.key;
      Squadron.finer('Finer - ${logLevel.value}');
    }

    expect(memoryLogger.length, equals(2));
    expect(memoryLogger.contains('Finer - FINEST'), isTrue);
    expect(memoryLogger.contains('Finer - FINER'), isTrue);
  });

  test('Fine', () {
    for (var logLevel in logLevels.entries) {
      Squadron.logLevel = logLevel.key;
      Squadron.fine('Fine - ${logLevel.value}');
    }

    expect(memoryLogger.length, equals(3));
    expect(memoryLogger.contains('Fine - FINEST'), isTrue);
    expect(memoryLogger.contains('Fine - FINER'), isTrue);
    expect(memoryLogger.contains('Fine - FINE'), isTrue);
  });

  test('Config', () {
    for (var logLevel in logLevels.entries) {
      Squadron.logLevel = logLevel.key;
      Squadron.config('Config - ${logLevel.value}');
    }

    expect(memoryLogger.length, equals(4));
    expect(memoryLogger.contains('Config - FINEST'), isTrue);
    expect(memoryLogger.contains('Config - FINER'), isTrue);
    expect(memoryLogger.contains('Config - FINE'), isTrue);
    expect(memoryLogger.contains('Config - CONFIG'), isTrue);
  });

  test('Info', () {
    for (var logLevel in logLevels.entries) {
      Squadron.logLevel = logLevel.key;
      Squadron.info('Info - ${logLevel.value}');
    }

    expect(memoryLogger.length, equals(5));
    expect(memoryLogger.contains('Info - FINEST'), isTrue);
    expect(memoryLogger.contains('Info - FINER'), isTrue);
    expect(memoryLogger.contains('Info - FINE'), isTrue);
    expect(memoryLogger.contains('Info - CONFIG'), isTrue);
    expect(memoryLogger.contains('Info - INFO'), isTrue);
  });

  test('Warning', () {
    for (var logLevel in logLevels.entries) {
      Squadron.logLevel = logLevel.key;
      Squadron.warning('Warning - ${logLevel.value}');
    }

    expect(memoryLogger.length, equals(6));
    expect(memoryLogger.contains('Warning - FINEST'), isTrue);
    expect(memoryLogger.contains('Warning - FINER'), isTrue);
    expect(memoryLogger.contains('Warning - FINE'), isTrue);
    expect(memoryLogger.contains('Warning - CONFIG'), isTrue);
    expect(memoryLogger.contains('Warning - INFO'), isTrue);
    expect(memoryLogger.contains('Warning - WARNING'), isTrue);
  });

  test('Severe', () {
    for (var logLevel in logLevels.entries) {
      Squadron.logLevel = logLevel.key;
      Squadron.severe('Severe - ${logLevel.value}');
    }

    expect(memoryLogger.length, equals(7));
    expect(memoryLogger.contains('Severe - FINEST'), isTrue);
    expect(memoryLogger.contains('Severe - FINER'), isTrue);
    expect(memoryLogger.contains('Severe - FINE'), isTrue);
    expect(memoryLogger.contains('Severe - CONFIG'), isTrue);
    expect(memoryLogger.contains('Severe - INFO'), isTrue);
    expect(memoryLogger.contains('Severe - WARNING'), isTrue);
    expect(memoryLogger.contains('Severe - SEVERE'), isTrue);
  });

  test('Shout', () {
    for (var logLevel in logLevels.entries) {
      Squadron.logLevel = logLevel.key;
      Squadron.shout('Shout - ${logLevel.value}');
    }

    expect(memoryLogger.length, equals(8));
    expect(memoryLogger.contains('Shout - FINEST'), isTrue);
    expect(memoryLogger.contains('Shout - FINER'), isTrue);
    expect(memoryLogger.contains('Shout - FINE'), isTrue);
    expect(memoryLogger.contains('Shout - CONFIG'), isTrue);
    expect(memoryLogger.contains('Shout - INFO'), isTrue);
    expect(memoryLogger.contains('Shout - WARNING'), isTrue);
    expect(memoryLogger.contains('Shout - SEVERE'), isTrue);
    expect(memoryLogger.contains('Shout - SHOUT'), isTrue);
  });

  test('Off', () {
    Squadron.logLevel = SquadronLogLevel.OFF;
    Squadron.finest('Finest');
    Squadron.finer('Finer');
    Squadron.fine('Fine');
    Squadron.config('Config');
    Squadron.info('Info');
    Squadron.warning('Warning');
    Squadron.severe('Severe');
    Squadron.shout('Shout');

    expect(memoryLogger.length, equals(0));
  });

  test('Squadron ID', () {
    expect(Squadron.id, equals('workerTests'));
    Squadron.setId('should fail');
    expect(Squadron.id, equals('workerTests'));

    Squadron.info('Squadron ID Test');
    expect(memoryLogger.length, equals(1));
    expect(memoryLogger.contains(Squadron.id), isTrue);
    expect(memoryLogger.contains('Squadron ID Test'), isTrue);
  });

  test('Object', () {
    final map = {'test': 'Logging a map'};
    Squadron.info(map);
    expect(memoryLogger.length, equals(1));
    expect(memoryLogger.contains(map.toString()), isTrue);

    final obj = Object();
    Squadron.info(obj);
    expect(memoryLogger.length, equals(2));
    expect(memoryLogger.contains(obj.toString()), isTrue);
  });

  test('Iterable', () {
    final list = ['one', 'two', 'three'];
    Squadron.info(list);
    expect(memoryLogger.length, equals(list.length));
    expect(memoryLogger.contains('one'), isTrue);
    expect(memoryLogger.contains('two'), isTrue);
    expect(memoryLogger.contains('three'), isTrue);
    expect(memoryLogger.contains('\'one\''), isFalse);
    expect(memoryLogger.contains('\'two\''), isFalse);
    expect(memoryLogger.contains('\'three\''), isFalse);
  });

  test('Iterable of objects', () {
    final list = [Object(), 1, 'three', Future.value(1234567)];
    Squadron.info(list);
    expect(memoryLogger.length, equals(4));
    for (var item in list) {
      expect(memoryLogger.contains(item.toString()), isTrue);
    }
    expect(memoryLogger.contains('1234567'), isFalse);
  });

  test('Function', () {
    Squadron.info(() => 'log message from a function');
    expect(memoryLogger.length, equals(1));
    expect(memoryLogger.contains('log message from a function'), isTrue);
  });
}
