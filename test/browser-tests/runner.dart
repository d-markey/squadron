import 'dart:async';
import 'dart:js_interop';

import 'package:squadron/squadron.dart';
import 'package:web/web.dart';

import '../classes/test_context.dart';
import 'html_helpers.dart';
import 'html_logger.dart';
import 'runner_message.dart';
import 'test_runner.dart' as runner;

Future<void> bootstrap({required SquadronPlatformType workerPlatform}) async {
  final htmlLogger = HtmlLogger(document.findById<HTMLDivElement>('output')!);

  void reportStatus(JSAny? message) =>
      window.parent?.postMessage(message, origin);

  await runZonedGuarded(
    () async {
      print('Client platform type = ${Squadron.platformType.label}');

      TestContext? $context;

      Future<void> execute(Iterable<String> tests) async {
        final context = await runner.init(workerPlatform: workerPlatform);
        if (context == null) {
          print('Failed to initialize a test context');
          return;
        }

        $context = context;
        const max = 200;
        var pending = 0, stalledCount = 0;
        final timer = Timer.periodic(Duration(milliseconds: 100), (t) {
          if (context.pending == pending) {
            stalledCount++;
            if (stalledCount < max / 4) {
              // keep silent...
            } else if (stalledCount < max / 2 && stalledCount % 5 == 0) {
              reportStatus(
                  'Stalled at $pending ($stalledCount / $max)...'.toJS);
            } else if (stalledCount < max && stalledCount % 10 == 0) {
              reportStatus(
                  'Stalled at $pending ($stalledCount / $max)...'.toJS);
            } else if (stalledCount > max) {
              reportStatus('Stalled at $pending, cancelling tests...'.toJS);
              context.cancel();
            }
          } else {
            stalledCount = 0;
            pending = context.pending;
            reportStatus('$pending tests pending...'.toJS);
          }
        });

        runner.launch(context, tests);
        await context.waitForCompletion();
        timer.cancel();

        reportStatus(context.isCancelled ? 'Cancelled'.toJS : 'Done'.toJS);
        $context = null;
      }

      window.onMessage.listen((m) async {
        final msg = m.data.toRunnerMessage;
        if (msg == RunnerMessage.run) {
          if ($context != null) {
            print('(*) Tests are already running');
          } else if (msg.tests.isEmpty) {
            print('(*) No tests to run');
          } else {
            print('(*) Launching tests');
            await execute(msg.tests);
          }
        } else if (msg == RunnerMessage.cancelled) {
          if ($context != null) {
            print('(*) Cancel tests');
            $context?.cancel();
            $context = null;
          }
        } else {
          print('(*) ${msg.message}');
        }
      });

      reportStatus(RunnerMessage.ready.toJS);
    },
    uncaughtExceptionHandler('R'),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => htmlLogger.log(line),
    ),
  );
}
