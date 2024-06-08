class ConsoleToHtml {
  Iterable<String> convert(String message) sync* {
    while (message.endsWith('\r') || message.endsWith('\n')) {
      message = message.substring(0, message.length - 1);
    }
    final codeUnits = message.codeUnits;
    final closeTags = <int>[];
    final html = <int>[];
    var i = 0;
    while (i < codeUnits.length) {
      final replacements =
          sequences.where((s) => s.match(codeUnits, i)).toList();
      if (replacements.length == 1) {
        final replacement = replacements[0];
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
        i += replacement.length;
      } else {
        html.add(codeUnits[i]);
        i += 1;
      }
    }
    // ensure tags are closed
    html.addAll(closeTags);
    closeTags.clear();
    yield String.fromCharCodes(html);
  }

  static final esc = 27;
  static final cr = SequenceReplacement('\n'.codeUnits, '');
  static final lf = SequenceReplacement('\r'.codeUnits, '');
  static final amp = SequenceReplacement('&'.codeUnits, '&amp;');
  static final lt = SequenceReplacement('<'.codeUnits, '&lt;');
  static final gt = SequenceReplacement('>'.codeUnits, '&gt;');
  static final resetSeq = SequenceReplacement([esc, ...'[0m'.codeUnits], '');
  static final boldSeq =
      SequenceReplacement([esc, ...'[1m'.codeUnits], '<b>', '</b>');
  static final redSeq = SequenceReplacement(
      [esc, ...'[31m'.codeUnits], '<span class="red">', '</span>');
  static final greenSeq = SequenceReplacement(
      [esc, ...'[32m'.codeUnits], '<span class="green">', '</span>');

  static final sequences = [
    cr,
    lf,
    amp,
    lt,
    gt,
    resetSeq,
    boldSeq,
    redSeq,
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
