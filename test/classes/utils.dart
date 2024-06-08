import 'package:test/test.dart';

Exception unexpectedSuccess(String process, [dynamic res]) =>
    Exception('$process completed successfully with res=$res');

Matcher mentions(Object? x) => contains(contains(x));
Matcher doesNotMention(Object? x) => isNot(contains(contains(x)));

void caseCheck(dynamic object, Matcher matcher) =>
    expect(object.toString(), matcher);

void lowerCaseCheck(dynamic object, Matcher matcher) =>
    expect(object.toString().toLowerCase(), matcher);

void upperCaseCheck(dynamic object, Matcher matcher) =>
    expect(object.toString().toUpperCase(), matcher);
