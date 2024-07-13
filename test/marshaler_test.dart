@TestOn('vm || browser')
library;

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/test_service_worker.dart';

void main() async {
  final testContext = await TestContext.init('');
  execute(testContext);
}

String testScript = 'marshaler_test.dart';

void execute(TestContext tc) {
  tc.run(() {
    tc.group("- Marshaler", () {
      late TestWorker testWorker;

      setUpAll(() async {
        testWorker = TestWorker(tc);
        await testWorker.start();
      });

      tearDownAll(() {
        testWorker.release();
      });

      tc.test('- unmarshaled "non-native" types work in VM, fail on Web',
          () async {
        try {
          final sum = await testWorker.bigIntAdd(
            BigInt.from(7),
            BigInt.from(5),
            marshalIn: false,
            marshalOut: false,
          );
          if (tc.workerPlatform.isJsOrWasm) {
            throw unexpectedSuccess('unmarshalled call to bigIntAdd()', sum);
          } else {
            expect(sum, equals(BigInt.from(12)));
          }
        } on SquadronError catch (ex) {
          if (tc.workerPlatform.isJsOrWasm) {
            lowerCaseCheck(ex.message, contains('failed to post message'));
          } else {
            rethrow;
          }
        }
      });

      tc.test('- unmarshaled "non-native" input types work in VM, fail on Web',
          () async {
        try {
          final sum = await testWorker.bigIntAdd(
            BigInt.from(7),
            BigInt.from(5),
            marshalIn: false,
            marshalOut: true,
          );
          if (tc.workerPlatform.isJsOrWasm) {
            throw unexpectedSuccess('unmarshalled call to bigIntAdd()', sum);
          } else {
            expect(sum, equals(BigInt.from(12)));
          }
        } on SquadronError catch (ex) {
          if (tc.workerPlatform.isJsOrWasm) {
            lowerCaseCheck(ex.message, contains('failed to post message'));
          } else {
            rethrow;
          }
        }
      });

      tc.test('- unmarshaled "non-native" output types work in VM, fail on Web',
          () async {
        try {
          final sum = await testWorker.bigIntAdd(
            BigInt.from(7),
            BigInt.from(5),
            marshalIn: true,
            marshalOut: false,
          );
          if (tc.workerPlatform.isJsOrWasm) {
            throw unexpectedSuccess('unmarshalled call to bigIntAdd()', sum);
          } else {
            expect(sum, equals(BigInt.from(12)));
          }
        } on SquadronError catch (ex) {
          if (tc.workerPlatform.isJsOrWasm) {
            lowerCaseCheck(ex.message, contains('failed to post message'));
          } else {
            rethrow;
          }
        }
      });

      tc.test('- marshaled "non-native" types always work', () async {
        final sum = await testWorker.bigIntAdd(
          BigInt.from(7),
          BigInt.from(5),
          marshalIn: true,
          marshalOut: true,
        );
        expect(sum, equals(BigInt.from(12)));
      });
    });
  });
}
