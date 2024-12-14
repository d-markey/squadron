abstract class TestException implements Exception {
  TestException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class TestCancelledException extends TestException {
  TestCancelledException([super.message = 'Cancelled']);
}

class TestTimeOutException extends TestException {
  TestTimeOutException([super.message = 'Timeout']);
}
