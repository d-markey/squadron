import 'dart:async';

import 'package:squadron/squadron.dart';

import '../classes/test_context.dart';
import 'test_suites.dart';

Future<TestContext?> init({SquadronPlatformType? workerPlatform}) =>
    TestContext.init(
      RunMode.launch,
      '~/..',
      workerPlatform ?? Squadron.platformType,
    );

Future<Iterable<({String label, int tests})>> discover() async {
  final context = await TestContext.init(
    RunMode.discover,
    '~/..',
    Squadron.platformType,
  );
  if (context == null) {
    print('Failed to initialize a test context');
    return const [];
  }

  for (var testSuite in testSuites) {
    context.discover(testSuite.runner);
  }
  await context.waitForCompletion();

  return context.rootGroups;
}

void launch(TestContext context, Iterable<String> testLabels) {
  if (testLabels.isEmpty) return;

  for (var testLabel in testLabels) {
    context.onlyTests.add(
      RegExp('^${RegExp.escape(testLabel)}.*', caseSensitive: false),
    );
  }

  print('Selected tests: ${testLabels.join(', ')}');
  print('Test client running on ${context.clientPlatformName}');
  print('Workers running on ${context.workerPlatformName}');

  for (var testSuite in testSuites) {
    testSuite.runner(context);
  }
}
