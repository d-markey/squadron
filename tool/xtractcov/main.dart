import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    final input = await File('./doc/coverage/xml/index.xml').readAsString();

    final lineRate = double.tryParse(
        RegExp('\\<coverage\\s+.*line-rate="(\\d+\\.\\d+)"')
                .firstMatch(input)
                ?.group(1) ??
            '');

    if (lineRate == null) {
      throw Exception('line-rate not found');
    }

    final linesValid = await _calculateRealLoc();

    await File('./coverage.json').writeAsString(jsonEncode({
      'linesValid': linesValid,
      'lineRate': (lineRate * 1000).round() / 10,
    }));
    exit(0);
  } catch (ex) {
    stderr.writeln(ex);
    exit(1);
  }
}

/// Combined regex for all Dart string types
final _stringRegex = RegExp(
  r"(r?'''[\s\S]*?''')|" // Triple-single quotes
  r'(r?"""[\s\S]*?""")|' // Triple-double quotes
  r"(r?'(\\.|[^'\\])*')|" // Single-single quotes
  r'(r?"(\\.|[^"\\])*")', // Single-double quotes
  multiLine: true,
);

Future<int> _calculateRealLoc() async {
  final libDir = Directory('lib');
  if (!await libDir.exists()) return 0;

  var totalLoc = 0;

  final dartFiles = await libDir
      .list(recursive: true)
      .where((f) => f is File && f.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  for (final file in dartFiles) {
    var content = await file.readAsString();

    // 1. Neutralize strings
    content = content.replaceAllMapped(_stringRegex, (match) {
      final text = match.group(0)!;
      final newlineCount = text.split('\n').length - 1;
      return newlineCount == 0 ? '***' : "'''${'***\n' * newlineCount}'''";
    });

    // 2. Remove comments
    content = _stripComments(content);

    // 3. Count non-empty lines
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        totalLoc++;
      }
    }
  }

  return totalLoc;
}

String _stripComments(String code) {
  final result = StringBuffer();
  var i = 0;
  var blockDepth = 0;
  var inLineComment = false;

  while (i < code.length) {
    if (inLineComment) {
      if (code[i] == '\n') {
        inLineComment = false;
        result.write('\n');
      }
      i++;
    } else if (blockDepth > 0) {
      if (i + 1 < code.length && code[i] == '/' && code[i + 1] == '*') {
        blockDepth++;
        i += 2;
      } else if (i + 1 < code.length && code[i] == '*' && code[i + 1] == '/') {
        blockDepth--;
        i += 2;
      } else {
        i++;
      }
    } else {
      if (i + 1 < code.length && code[i] == '/' && code[i + 1] == '/') {
        inLineComment = true;
        i += 2;
      } else if (i + 1 < code.length && code[i] == '/' && code[i + 1] == '*') {
        blockDepth = 1;
        i += 2;
      } else {
        result.write(code[i]);
        i++;
      }
    }
  }
  return result.toString();
}
