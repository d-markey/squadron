import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    final input = await File('./coverage/xml/index.xml').readAsString();
    final linesValid = int.tryParse(
        RegExp('\\<coverage\\s+.*lines-valid="(\\d+)"')
                .firstMatch(input)
                ?.group(1) ??
            '');
    final lineRate = double.tryParse(
        RegExp('\\<coverage\\s+.*line-rate="(\\d+\\.\\d+)"')
                .firstMatch(input)
                ?.group(1) ??
            '');
    if (linesValid == null) {
      throw Exception('lines-valid not found');
    }
    if (lineRate == null) {
      throw Exception('line-rate not found');
    }
    await File('./coverage.json').writeAsString(jsonEncode({
      'linesValid': linesValid,
      'lineRate': (lineRate * 1000).round() / 10
    }));
    exit(0);
  } catch (ex) {
    stderr.writeln(ex);
    exit(1);
  }
}
