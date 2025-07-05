import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

import 'platform.dart';

typedef ExceptionHandler = void Function(Object ex, [StackTrace? st]);

ExceptionHandler uncaughtExceptionHandler(String info) => (ex, [st]) {
      $log('[$info] EXCEPTION $ex');
      $log('[$info] STACKTRACE: $st');
    };

class UnexpectedException implements Exception {
  UnexpectedException(this.message);

  final String message;

  @override
  String toString() => message;
}

UnexpectedException unexpectedSuccess(String process, [dynamic res]) =>
    UnexpectedException((res == null)
        ? 'Unexpected: $process completed successfully'
        : 'Unexpected: $process completed successfully with res=$res');

UnexpectedException unexpectedFailure(String process, [dynamic ex]) =>
    UnexpectedException((ex == null)
        ? 'Unexpected: $process failed'
        : 'Unexpected: $process failed with ex=$ex');

Matcher isNotA<T>() => isNot(isA<T>());

// for lists of strings
Matcher mentions(Pattern re) => contains(matches(re));
Matcher doesNotMention(Pattern re) => isNot(mentions(re));

// for stack traces
Matcher hasCalled(dynamic matcher) =>
    Called(matcher is String ? matches(matcher) : matcher);
Matcher hasNotCalled(dynamic matcher) => isNot(hasCalled(matcher));

class Called extends CustomMatcher {
  Called(Matcher matcher)
      : super('Stack trace that called', 'stack trace', matcher);

  @override
  Object? featureValueOf(dynamic actual) =>
      (actual is StackTrace) ? actual.toString() : null;
}

// for errors
Matcher reports(Pattern matcher) => Reported(matches(matcher));
Matcher doesNotReport(Pattern matcher) => isNot(reports(matcher));

Matcher failsWith<E>() => throwsA(isA<E>());

class Reported extends CustomMatcher {
  Reported(dynamic matcher)
      : super('Error that reported', 'error message', matcher);

  @override
  Object? featureValueOf(dynamic actual) =>
      (actual is SquadronException) ? actual.message : actual.toString();
}

void checkOutcome<X, Y>(String process, X a, X b, Y Function(X) test,
    SquadronPlatformType platform) {
  try {
    final ra = test(a);
    final rb = test(b);
    expect(ra, rb);
  } catch (exa, sta) {
    try {
      final rb = test(b);
      print('$process succeeded for $b with $rb, failed for $a with $exa');
      throw unexpectedSuccess(process, rb);
    } catch (exb, stb) {
      try {
        expect(exa.runtimeType, exb.runtimeType);
        expect(exa.toString(), exb.toString());
      } catch (_) {
        print(
            '$process failed with inconsistent errors: for $a with $exa, for $b with $exb');
        if (platform.isWasm && process == 'subList (invalid range)') {
          // ignore until https://github.com/dart-lang/sdk/issues/61045 is fixed
        } else {
          print('Stacktrace (a): $sta');
          print('Stacktrace (b): $stb');
          rethrow;
        }
      }
    }
  }
}
