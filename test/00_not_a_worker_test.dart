// ignore_for_file: file_names

import 'package:squadron/squadron.dart';
import 'package:test/test.dart';
import 'package:using/using.dart';

import 'src/test_context.dart';
import 'worker_services/not_a_worker_service.dart';

Future<void> main() => TestContext.run(execute);

const testScript = '00_not_a_worker_test.dart';

void execute(TestContext? tc) {
  if (tc == null) return;

  tc.launch(() {
    tc.group('- NOT A WORKER', () {
      tc.test('- Dart program (VM)', () async {
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

      tc.test('- Dart program (Web)', () async {
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
