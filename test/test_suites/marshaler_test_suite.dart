import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import '../worker_services/_test_context.dart';
import '../worker_services/test_service_worker.dart';

void main() {
  group("- Marshaler", () {
    late TestWorker testWorker;

    setUpAll(() async {
      // Squadron.pushLogLevel(SquadronLogLevel.all);
      testWorker = TestWorker();
      await testWorker.start();
    });

    tearDownAll(() {
      // Squadron.popLogLevel();
      testWorker.stop();
    });

    test('- unmarshaled "non-native" types work in VM, fail on Web', () async {
      try {
        final sum = await testWorker.bigIntAdd(BigInt.from(7), BigInt.from(5),
            marshalIn: false, marshalOut: false);
        expect(sum, equals(BigInt.from(12)));
        if (TestContext.isJs) {
          throw Exception('must fail');
        }
      } on SquadronError catch (ex) {
        if (TestContext.isJs) {
          expect(ex.message, contains('structured clone'));
        } else {
          rethrow;
        }
      }
    });

    test('- unmarshaled "non-native" input types work in VM, fail on Web',
        () async {
      try {
        final sum = await testWorker.bigIntAdd(BigInt.from(7), BigInt.from(5),
            marshalIn: false, marshalOut: true);
        expect(sum, equals(BigInt.from(12)));
        if (TestContext.isJs) {
          throw Exception('must fail');
        }
      } on SquadronError catch (ex) {
        if (TestContext.isJs) {
          expect(ex.message, contains('structured clone'));
        } else {
          rethrow;
        }
      }
    });

    test('- unmarshaled "non-native" output types work in VM, fail on Web',
        () async {
      try {
        final sum = await testWorker.bigIntAdd(BigInt.from(7), BigInt.from(5),
            marshalIn: true, marshalOut: false);
        expect(sum, equals(BigInt.from(12)));
        if (TestContext.isJs) {
          throw Exception('must fail');
        }
      } on SquadronError catch (ex) {
        if (TestContext.isJs) {
          expect(ex.message, contains('structured clone'));
        } else {
          rethrow;
        }
      }
    });

    test('- marshaled "non-native" types always work', () async {
      final sum = await testWorker.bigIntAdd(BigInt.from(7), BigInt.from(5),
          marshalIn: true, marshalOut: true);
      expect(sum, equals(BigInt.from(12)));
    });
  });
}
