class TestFailedException implements Exception {
  TestFailedException(this.message);

  final String message;
}

void expect(bool test, String message) {
  if (!test) throw TestFailedException(message);
}
