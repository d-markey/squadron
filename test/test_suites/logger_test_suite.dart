import 'package:squadron/squadron.dart';
import 'package:squadron/src/squadron.dart';
import 'package:test/test.dart';

import '../classes/memory_logger.dart';

void loggerTests() {
  dynamic initialLogger;
  final memoryLogger = MemoryLogger();

  final logLevels = {
    SquadronLogLevel.debug: 'DEBUG',
    SquadronLogLevel.finest: 'FINEST',
    SquadronLogLevel.finer: 'FINER',
    SquadronLogLevel.fine: 'FINE',
    SquadronLogLevel.config: 'CONFIG',
    SquadronLogLevel.info: 'INFO',
    SquadronLogLevel.warning: 'WARNING',
    SquadronLogLevel.severe: 'SEVERE',
    SquadronLogLevel.shout: 'SHOUT',
  };

  setUp(() {
    initialLogger = LoggerExt.logger;
    memoryLogger.clear();
    Squadron.pushLogLevel(SquadronLogLevel.all);
    Squadron.setLogger(memoryLogger);
    Squadron.debugMode = false;
  });

  tearDown(() {
    Squadron.setLogger(initialLogger);
    Squadron.popLogLevel();
    Squadron.debugMode = false;
  });

  group('- Log levels', () {
    test('- Debug - debugMode = false', () {
      for (var logLevel in logLevels.entries) {
        Squadron.logLevel = logLevel.key;
        Squadron.debug('Debug - ${logLevel.value}');
      }

      expect(memoryLogger.length, equals(1));
      expect(memoryLogger.contains('Debug - DEBUG'), isTrue);
    });

    test('- Debug - debugMode = true', () {
      Squadron.debugMode = true;
      for (var logLevel in logLevels.entries) {
        Squadron.logLevel = logLevel.key;
        Squadron.debug('Debug - ${logLevel.value}');
      }

      expect(memoryLogger.length, equals(logLevels.length));
    });

    test('- Finest', () {
      for (var logLevel in logLevels.entries) {
        Squadron.logLevel = logLevel.key;
        Squadron.finest('Finest - ${logLevel.value}');
      }

      expect(memoryLogger.length, equals(2));
      expect(memoryLogger.contains('Finest - DEBUG'), isTrue);
      expect(memoryLogger.contains('Finest - FINEST'), isTrue);
    });

    test('- Finer', () {
      for (var logLevel in logLevels.entries) {
        Squadron.logLevel = logLevel.key;
        Squadron.finer('Finer - ${logLevel.value}');
      }

      expect(memoryLogger.length, equals(3));
      expect(memoryLogger.contains('Finer - DEBUG'), isTrue);
      expect(memoryLogger.contains('Finer - FINEST'), isTrue);
      expect(memoryLogger.contains('Finer - FINER'), isTrue);
    });

    test('- Fine', () {
      for (var logLevel in logLevels.entries) {
        Squadron.logLevel = logLevel.key;
        Squadron.fine('Fine - ${logLevel.value}');
      }

      expect(memoryLogger.length, equals(4));
      expect(memoryLogger.contains('Fine - DEBUG'), isTrue);
      expect(memoryLogger.contains('Fine - FINEST'), isTrue);
      expect(memoryLogger.contains('Fine - FINER'), isTrue);
      expect(memoryLogger.contains('Fine - FINE'), isTrue);
    });

    test('- Config', () {
      for (var logLevel in logLevels.entries) {
        Squadron.logLevel = logLevel.key;
        Squadron.config('Config - ${logLevel.value}');
      }

      expect(memoryLogger.length, equals(5));
      expect(memoryLogger.contains('Config - DEBUG'), isTrue);
      expect(memoryLogger.contains('Config - FINEST'), isTrue);
      expect(memoryLogger.contains('Config - FINER'), isTrue);
      expect(memoryLogger.contains('Config - FINE'), isTrue);
      expect(memoryLogger.contains('Config - CONFIG'), isTrue);
    });

    test('- Info', () {
      for (var logLevel in logLevels.entries) {
        Squadron.logLevel = logLevel.key;
        Squadron.info('Info - ${logLevel.value}');
      }

      expect(memoryLogger.length, equals(6));
      expect(memoryLogger.contains('Info - DEBUG'), isTrue);
      expect(memoryLogger.contains('Info - FINEST'), isTrue);
      expect(memoryLogger.contains('Info - FINER'), isTrue);
      expect(memoryLogger.contains('Info - FINE'), isTrue);
      expect(memoryLogger.contains('Info - CONFIG'), isTrue);
      expect(memoryLogger.contains('Info - INFO'), isTrue);
    });

    test('- Warning', () {
      for (var logLevel in logLevels.entries) {
        Squadron.logLevel = logLevel.key;
        Squadron.warning('Warning - ${logLevel.value}');
      }

      expect(memoryLogger.length, equals(7));
      expect(memoryLogger.contains('Warning - DEBUG'), isTrue);
      expect(memoryLogger.contains('Warning - FINEST'), isTrue);
      expect(memoryLogger.contains('Warning - FINER'), isTrue);
      expect(memoryLogger.contains('Warning - FINE'), isTrue);
      expect(memoryLogger.contains('Warning - CONFIG'), isTrue);
      expect(memoryLogger.contains('Warning - INFO'), isTrue);
      expect(memoryLogger.contains('Warning - WARNING'), isTrue);
    });

    test('- Severe', () {
      for (var logLevel in logLevels.entries) {
        Squadron.logLevel = logLevel.key;
        Squadron.severe('Severe - ${logLevel.value}');
      }

      expect(memoryLogger.length, equals(8));
      expect(memoryLogger.contains('Severe - DEBUG'), isTrue);
      expect(memoryLogger.contains('Severe - FINEST'), isTrue);
      expect(memoryLogger.contains('Severe - FINER'), isTrue);
      expect(memoryLogger.contains('Severe - FINE'), isTrue);
      expect(memoryLogger.contains('Severe - CONFIG'), isTrue);
      expect(memoryLogger.contains('Severe - INFO'), isTrue);
      expect(memoryLogger.contains('Severe - WARNING'), isTrue);
      expect(memoryLogger.contains('Severe - SEVERE'), isTrue);
    });

    test('- Shout', () {
      for (var logLevel in logLevels.entries) {
        Squadron.logLevel = logLevel.key;
        Squadron.shout('Shout - ${logLevel.value}');
      }

      expect(memoryLogger.length, equals(9));
      expect(memoryLogger.contains('Shout - DEBUG'), isTrue);
      expect(memoryLogger.contains('Shout - FINEST'), isTrue);
      expect(memoryLogger.contains('Shout - FINER'), isTrue);
      expect(memoryLogger.contains('Shout - FINE'), isTrue);
      expect(memoryLogger.contains('Shout - CONFIG'), isTrue);
      expect(memoryLogger.contains('Shout - INFO'), isTrue);
      expect(memoryLogger.contains('Shout - WARNING'), isTrue);
      expect(memoryLogger.contains('Shout - SEVERE'), isTrue);
      expect(memoryLogger.contains('Shout - SHOUT'), isTrue);
    });

    test('- Off', () {
      Squadron.logLevel = SquadronLogLevel.off;
      Squadron.finest('Debug');
      Squadron.finest('Finest');
      Squadron.finer('Finer');
      Squadron.fine('Fine');
      Squadron.config('Config');
      Squadron.info('Info');
      Squadron.warning('Warning');
      Squadron.severe('Severe');
      Squadron.shout('Shout');

      expect(memoryLogger.length, isZero);
    });

    test('- Push/pop', () {
      final header = '[${Squadron.id}]';
      int message = 0;
      final expectedMessages = <String>[];

      Squadron.logLevel = SquadronLogLevel.debug;
      Squadron.debug(++message); // 1 logged
      Squadron.config(++message); // 2 logged
      Squadron.info(++message); // 3 logged
      expectedMessages.addAll(['$header 1', '$header 2', '$header 3']);

      Squadron.pushLogLevel(SquadronLogLevel.config);
      expect(Squadron.logLevel, equals(SquadronLogLevel.config));
      Squadron.debug(++message); // 4 not logged
      Squadron.config(++message); // 5 logged
      Squadron.info(++message); // 6 logged
      expectedMessages.addAll(['$header 5', '$header 6']);

      Squadron.pushLogLevel(SquadronLogLevel.info);
      expect(Squadron.logLevel, equals(SquadronLogLevel.info));
      Squadron.debug(++message); // 7 not logged
      Squadron.config(++message); // 8 not logged
      Squadron.info(++message); // 9 logged
      expectedMessages.addAll(['$header 9']);

      expect(Squadron.popLogLevel(), equals(SquadronLogLevel.config));
      expect(Squadron.logLevel, equals(SquadronLogLevel.config));
      Squadron.debug(++message); // 10 not logged
      Squadron.config(++message); // 11 logged
      Squadron.info(++message); // 12 logged
      expectedMessages.addAll(['$header 11', '$header 12']);

      expect(Squadron.popLogLevel(), equals(SquadronLogLevel.debug));
      expect(Squadron.logLevel, equals(SquadronLogLevel.debug));
      Squadron.debug(++message); // 13 logged
      Squadron.config(++message); // 14 logged
      Squadron.info(++message); // 15 logged
      expectedMessages.addAll(['$header 13', '$header 14', '$header 15']);

      expect(memoryLogger.length, equals(expectedMessages.length));
      expect(memoryLogger.messages, equals(expectedMessages));
    });
  });

  group('- Log messages of various types', () {
    test('- Object', () {
      final map = {'test': 'Logging a map'};
      Squadron.info(map);
      expect(memoryLogger.length, equals(1));
      expect(memoryLogger.contains(map.toString()), isTrue);

      final obj = Object();
      Squadron.info(obj);
      expect(memoryLogger.length, equals(2));
      expect(memoryLogger.contains(obj.toString()), isTrue);
    });

    test('- Iterable', () {
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

    test('- Iterable of objects', () {
      final value = 1234567;
      final list = [Object(), 1, 'three', Future.value(value)];
      Squadron.info(list);
      expect(memoryLogger.length, equals(4));
      for (var item in list) {
        expect(memoryLogger.contains(item.toString()), isTrue);
      }
      expect(memoryLogger.contains(list.toString()), isFalse);
      expect(memoryLogger.contains(value.toString()), isFalse);
    });

    test('- Function', () {
      Squadron.info(() => 'log message from a function');
      expect(memoryLogger.length, equals(1));
      expect(memoryLogger.contains('log message from a function'), isTrue);
    });

    test('- Multiline', () {
      final message = 'log message\nspanning\nseveral lines';
      Squadron.info(message);
      final lines = message.split('\n');
      expect(memoryLogger.length, equals(lines.length));
      for (var i = 0; i < lines.length; i++) {
        expect(memoryLogger.contains(lines[i]), isTrue);
      }
      expect(memoryLogger.contains(message), isFalse);
    });
  });

  test('- Squadron ID', () {
    expect(Squadron.id, equals('workerTests'));
    Squadron.setId('should have no effect');
    expect(Squadron.id, equals('workerTests'));

    Squadron.info('Squadron ID Test');
    expect(memoryLogger.length, equals(1));
    expect(memoryLogger.contains('should have no effect'), isFalse);
    expect(memoryLogger.contains('[workerTests]'), isTrue);
    expect(memoryLogger.contains('Squadron ID Test'), isTrue);
  });
}
