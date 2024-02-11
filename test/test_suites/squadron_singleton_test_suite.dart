import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import '../classes/platform.dart';

void main() {
  group('- Squadron Singleton', () {
    setUp(() {
      Squadron.shutdown();
    });

    tearDown(() {
      Squadron.shutdown();
    });

    group('- uninitialized', () {
      test('- log level is off by default', () {
        expect(Squadron.isInitialized, isFalse);
        expect(Squadron.logLevel, equals(SquadronLogLevel.off));
      });

      test('- id is empty by default', () {
        expect(Squadron.isInitialized, isFalse);
        expect(Squadron.id, isNull);
      });

      test('- reading log level does not initialize the Squadron singleton',
          () {
        expect(Squadron.isInitialized, isFalse);
        expect(Squadron.logLevel, equals(SquadronLogLevel.off));
        expect(Squadron.isInitialized, isFalse);
      });

      test('- reading debug mode does not initialize the Squadron singleton',
          () {
        expect(Squadron.isInitialized, isFalse);
        expect(Squadron.debugMode, isFalse);
        expect(Squadron.isInitialized, isFalse);
      });

      test('- setting debug mode does not initialize the Squadron singleton',
          () {
        expect(Squadron.isInitialized, isFalse);
        expect(Squadron.debugMode, isFalse);
        Squadron.debugMode = true;
        expect(Squadron.isInitialized, isFalse);
        expect(Squadron.debugMode, isTrue);
      });
    });

    group('- initialization', () {
      test('- setting id initializes the Squadron singleton', () {
        expect(Squadron.isInitialized, isFalse);
        Squadron.setId('test');
        expect(Squadron.isInitialized, isTrue);
      });

      test('- setting log level initializes the Squadron singleton', () {
        expect(Squadron.isInitialized, isFalse);
        Squadron.logLevel = SquadronLogLevel.info;
        expect(Squadron.isInitialized, isTrue);
      });

      test('- pushing log level initializes the Squadron singleton', () {
        expect(Squadron.isInitialized, isFalse);
        Squadron.pushLogLevel(SquadronLogLevel.info);
        expect(Squadron.isInitialized, isTrue);
      });

      test('- setting logger initializes the Squadron singleton', () {
        expect(Squadron.isInitialized, isFalse);
        Squadron.setLogger(ConsoleSquadronLogger());
        expect(Squadron.isInitialized, isTrue);
      });

      test('- setting parent initializes the Squadron singleton', () {
        expect(Squadron.isInitialized, isFalse);
        final parent = getWorkerChannel();
        Squadron.setParent(parent!);
        expect(Squadron.isInitialized, isTrue);
      });
    });

    test('- Shutdown', () {
      expect(Squadron.isInitialized, isFalse);
      Squadron.setId('test');
      expect(Squadron.isInitialized, isTrue);
      expect(Squadron.id, equals('test'));

      Squadron.shutdown();
      expect(Squadron.isInitialized, isFalse);
      expect(Squadron.id, isNull);
    });
  });
}
