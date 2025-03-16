import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:squadron/squadron.dart';
import 'package:squadron/version.dart';
import 'package:web/web.dart';

import 'console_to_html.dart';
import 'html_helpers.dart';
import 'html_logger.dart';
import 'runner_message.dart';
import 'test_context.dart';
import 'test_runner.dart' as runner;

Future<void> bootstrap({required SquadronPlatformType workerPlatform}) async {
  final htmlLogger = HtmlLogger(document.findById<HTMLDivElement>('output')!);

  window.setProperty('dartPrint'.toJS, htmlLogger.log.toJS);

  Log.writeln(
      'Test Runner: ${Squadron.platformType.label} platform using Squadron $version',
      [Log.bold]);

  TestContext? $context;

  Future<void> execute(Iterable<String> tests) async {
    final context = await runner.init(workerPlatform: workerPlatform);
    if (context == null) {
      Log.writeln('Failed to initialize a test context', [Log.red]);
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
          window.notify('Stalled at $pending ($stalledCount / $max)...'.toJS);
        } else if (stalledCount < max && stalledCount % 10 == 0) {
          window.notify('Stalled at $pending ($stalledCount / $max)...'.toJS);
        } else if (stalledCount > max) {
          window.notify('Stalled at $pending, cancelling tests...'.toJS);
          Future.delayed(Duration(milliseconds: 250), context.cancel);
        }
      } else {
        stalledCount = 0;
        pending = context.pending;
        var status = '';
        if (htmlLogger.errors == 1) {
          status = '1 error - ';
        } else if (htmlLogger.errors > 1) {
          status = '${htmlLogger.errors} errors - ';
        }
        if (context.isCancelled) {
          status += 'Tests cancelled - ';
        }
        window.notify('$status$pending tests pending...'.toJS);
      }
    });

    runner.launch(context, tests);

    window.notify(RunnerMessage.started.toJS);
    await context.wait().whenComplete(timer.cancel);
    if (htmlLogger.isSuspended) {
      htmlLogger.resumeUIUpdates();
    }
    window.notify(RunnerMessage.done.toJS);
    window.notify(
        context.isCancelled ? 'Tests cancelled'.toJS : 'Tests completed'.toJS);
    $context = null;
  }

  window.onMessage.listen((m) async {
    final msg = m.data.dartify().toString();
    if (msg.startsWith(RunnerMessage.run)) {
      if ($context != null) {
        Log.writeln('Tests are already running');
      } else if (msg.tests.isNotEmpty) {
        Log.writeln('Launching tests...');
        await execute(msg.tests);
      }
    } else if (msg == RunnerMessage.cancel) {
      if ($context != null) {
        Log.writeln('Cancel tests');
        htmlLogger.suspendUIUpdates();
        $context?.cancel();
        $context = null;
      }
    } else if (msg == RunnerMessage.clear) {
      htmlLogger.clear();
    } else if (msg == RunnerMessage.nextError) {
      htmlLogger.showNextError();
    } else if (msg == RunnerMessage.previousError) {
      htmlLogger.showPrevError();
    } else {
      Log.writeln(msg);
    }
  });

  window.notify(RunnerMessage.ready.toJS);
}
