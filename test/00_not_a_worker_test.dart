// ignore_for_file: file_names

@TestOn('vm || browser')
library;

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'classes/test_context.dart';
import 'worker_services/not_a_worker_service.dart';

void main() {
  TestContext.init('~').then(execute);
  TestContext.init('~', SquadronPlatformType.wasm).then(execute);
}

String testScript = '00_not_a_worker_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  // print('client = ${tc.clientPlatform} / worker = ${tc.workerPlatform}');
  // print('  * supportsWasmGC = ${tc.supportsWasmGC}');
  // print('  * hasChromiumBreakIterators = ${tc.hasChromiumBreakIterators}');
  // print('  * hasImageCodecs = ${tc.hasImageCodecs}');
  // print('  * isCrossOriginIsolated = ${tc.isCrossOriginIsolated}');

  tc.run(() {
    tc.group('- Not a worker', () {
      tc.test("- Native worker", () async {
        await NotAWorker(tc).useAsync((w) async {
          var started = false, expired = false;
          Object? error;

          await Future.wait([
            w.start().then(
                  (_) => started = true,
                  onError: (ex) => (error = ex) == null,
                ),
            Future.delayed(Duration(seconds: 1)).then((_) => expired = true),
          ]);

          expect(expired, isTrue);
          expect(started, isFalse);
          expect(error, isA<SquadronError>());
        });
      }, skip: !tc.workerPlatform.isVm);

      tc.test("- Web worker", () async {
        await NotAWorker(tc).useAsync((w) async {
          var started = false, expired = false;
          Object? error;

          await Future.any([
            w.start().then(
                  (_) => started = true,
                  onError: (ex) => (error = ex) == null,
                ),
            Future.delayed(Duration(seconds: 1)).then((_) => expired = true),
          ]);

          expect(expired || (error is SquadronError), isTrue);
          expect(started, isFalse);
        });
      }, skip: !tc.workerPlatform.isWeb);
    });
  });
}
