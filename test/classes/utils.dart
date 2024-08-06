import 'package:squadron/squadron.dart';
import 'package:test/test.dart';

class UnexpectedSuccessException implements Exception {
  UnexpectedSuccessException(this.message);

  final String message;
}

UnexpectedSuccessException unexpectedSuccess(String process, [dynamic res]) =>
    UnexpectedSuccessException('$process completed successfully with res=$res');

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
Matcher reports(dynamic matcher) =>
    Reported(matcher is String ? matches(matcher) : matcher);
Matcher doesNotReport(dynamic matcher) => isNot(reports(matcher));

Matcher failsWith<E>() => throwsA(isA<E>());

class Reported extends CustomMatcher {
  Reported(Matcher matcher) : super('Error that reported', 'message', matcher);

  @override
  Object? featureValueOf(dynamic actual) =>
      (actual is SquadronException) ? actual.message : actual.toString();
}
