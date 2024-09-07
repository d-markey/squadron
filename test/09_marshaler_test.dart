// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'classes/test_context.dart';
import 'classes/utils.dart';
import 'worker_services/test_service_worker.dart';

void main() {
  TestContext.init('~').then(execute);
  TestContext.init('~', SquadronPlatformType.wasm).then(execute);
}

String testScript = '09_marshaler_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.run(() {
    tc.group("- Marshaler", () {
      late TestWorker testWorker;

      setUpAll(() async {
        testWorker = TestWorker(tc);
        await testWorker.start();
      });

      tearDownAll(() {
        testWorker.stop();
      });

      Future<BigInt> testSum(
              {required bool marshalIn, required bool marshalOut}) =>
          testWorker.bigIntAdd(BigInt.one, BigInt.two,
              marshalIn: marshalIn, marshalOut: marshalOut);

      tc.test('- unmarshaled "non-native" types work in VM, fail on Web',
          () async {
        try {
          final sum = await testSum(marshalIn: false, marshalOut: false);
          expect(sum, BigInt.from(3));
          if (tc.workerPlatform.isWeb) {
            throw unexpectedSuccess('unmarshalled call to bigIntAdd()', sum);
          }
        } on SquadronError catch (ex) {
          if (tc.workerPlatform.isVm) rethrow;
          expect(ex, reports('Failed to post request'));
        }
      });

      tc.test('- unmarshaled "non-native" input types work in VM, fail on Web',
          () async {
        try {
          final sum = await testSum(marshalIn: false, marshalOut: true);
          expect(sum, BigInt.from(3));
          if (tc.workerPlatform.isWeb) {
            throw unexpectedSuccess('unmarshalled call to bigIntAdd()', sum);
          }
        } on SquadronError catch (ex) {
          if (tc.workerPlatform.isVm) rethrow;
          expect(ex, reports('Failed to post request'));
        }
      });

      tc.test('- unmarshaled "non-native" output types work in VM, fail on Web',
          () async {
        try {
          final sum = await testSum(marshalIn: true, marshalOut: false);
          expect(sum, BigInt.from(3));
          if (tc.workerPlatform.isWeb) {
            throw unexpectedSuccess('unmarshalled call to bigIntAdd()', sum);
          }
        } on SquadronError catch (ex) {
          if (tc.workerPlatform.isVm) rethrow;
          expect(ex, reports('Failed to post response'));
        }
      });

      tc.test('- marshaled "non-native" types always work', () async {
        final sum = await testSum(marshalIn: true, marshalOut: true);
        expect(sum, BigInt.from(3));
      });
    });
  });
}
