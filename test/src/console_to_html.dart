sealed class Log {
  static void writeln(String text, [List<String Function(String)>? styles]) {
    if (styles != null) {
      for (var style in styles) {
        text = style(text);
      }
    }
    print(text);
  }

  static String bold(String text) =>
      String.fromCharCodes(ConsoleToHtml.boldSeq._sequence) +
      text +
      String.fromCharCodes(ConsoleToHtml.resetSeq._sequence);

  static String red(String text) =>
      String.fromCharCodes(ConsoleToHtml.redSeq._sequence) +
      text +
      String.fromCharCodes(ConsoleToHtml.resetSeq._sequence);

  static String green(String text) =>
      String.fromCharCodes(ConsoleToHtml.greenSeq._sequence) +
      text +
      String.fromCharCodes(ConsoleToHtml.resetSeq._sequence);
}

sealed class ConsoleToHtml {
  static Iterable<String> convert(String message) sync* {
    final codeUnits = message.codeUnits;
    var len = codeUnits.length - 1, idx = 0;
    while (len >= 0 && (codeUnits[len] == _cr || codeUnits[len] == _lf)) {
      len -= 1;
    }
    final closeTags = <int>[], html = <int>[];
    while (idx <= len) {
      final replacement =
          sequences.where((s) => s.match(codeUnits, idx)).firstOrNull;
      if (replacement != null) {
        if (replacement == resetSeq) {
          html.addAll(closeTags);
          closeTags.clear();
        } else if (replacement == cr || replacement == lf) {
          yield String.fromCharCodes(html);
          html.clear();
        } else {
          html.addAll(replacement.codeUnits);
          closeTags.addAll(replacement.closeTag);
        }
        idx += replacement.length;
      } else {
        html.add(codeUnits[idx]);
        idx += 1;
      }
    }
    // ensure tags are closed
    html.addAll(closeTags);
    closeTags.clear();
    yield String.fromCharCodes(html);
  }

  static final _cr = '\n'.codeUnits.first;
  static final _lf = '\r'.codeUnits.first;

  static final cr = SequenceReplacement([_cr], '');
  static final lf = SequenceReplacement([_lf], '');
  static final amp = SequenceReplacement('&'.codeUnits, '&amp;');
  static final lt = SequenceReplacement('<'.codeUnits, '&lt;');
  static final gt = SequenceReplacement('>'.codeUnits, '&gt;');
  static final resetSeq = SequenceReplacement('\u001b[0m'.codeUnits, '');
  static final boldSeq =
      SequenceReplacement('\u001b[1m'.codeUnits, '<b>', '</b>');
  static final redSeq = SequenceReplacement(
      '\u001b[31m'.codeUnits, '<span class="fail">', '</span>');
  static final yellowSeq = SequenceReplacement(
      '\u001b[33m'.codeUnits, '<span class="skip">', '</span>');
  static final greenSeq = SequenceReplacement(
      '\u001b[32m'.codeUnits, '<span class="pass">', '</span>');

  static final sequences = [
    cr,
    lf,
    amp,
    lt,
    gt,
    resetSeq,
    boldSeq,
    redSeq,
    yellowSeq,
    greenSeq,
  ];
}

class SequenceReplacement {
  SequenceReplacement(this._sequence, String replacement, [String? closeTag])
      : _codeUnits = replacement.codeUnits,
        _closeTag = closeTag?.codeUnits;

  final List<int> _sequence;
  final List<int> _codeUnits;
  final List<int>? _closeTag;

  int get length => _sequence.length;
  Iterable<int> get codeUnits => _codeUnits;
  Iterable<int> get closeTag => _closeTag ?? const <int>[];

  bool match(List<int> codeUnits, int index) {
    if (index + _sequence.length > codeUnits.length) return false;
    for (var i = 0; i < _sequence.length; i++) {
      if (codeUnits[index + i] != _sequence[i]) return false;
    }
    return true;
  }
}
