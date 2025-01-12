import 'dart:js_interop';

import 'package:web/web.dart';

import 'console_to_html.dart';
import 'html_helpers.dart';

class HtmlLogger {
  HtmlLogger(this._div) {
    _div.onscroll = _onScroll.toJS;
    _sw.start();
  }

  final Stopwatch _sw = Stopwatch();
  final HTMLDivElement _div;

  bool _scrollToEnd = true;
  bool _forceScroll = false;

  HTMLDivElement? _error;

  final _errorLines = <HTMLDivElement>[];

  int _errors = 0;
  int get errors => _errors;

  void _showError(HTMLDivElement? error) {
    _error?.classList.remove('highlight');
    if (error != null) {
      _scrollToEnd = false;
      _forceScroll = false;
      error.classList.add('highlight');
      error.scrollIntoView();
    }
    _error = error;
  }

  void showNextError() {
    if (_errorLines.isEmpty) return;
    final curIdx = (_error == null) ? -1 : _errorLines.indexOf(_error!);
    _showError(_errorLines[(curIdx + 1) % _errorLines.length]);
  }

  void showPrevError() {
    if (_errorLines.isEmpty) return;
    final curIdx =
        (_error == null) ? _errorLines.length : _errorLines.indexOf(_error!);
    _showError(_errorLines[(curIdx - 1) % _errorLines.length]);
  }

  void _onScroll(Event scrollEvent) {
    if (!_forceScroll) {
      _scrollToEnd =
          (_div.scrollHeight - _div.scrollTop) <= _div.clientHeight + 7;
    } else {
      _forceScroll = false;
    }
  }

  HTMLDivElement _log(Duration ts, String message) {
    if (message.isNotEmpty) {
      message = '[$ts] $message';
    }
    return _div.appendDiv(html: message);
  }

  void log(JSAny? message) {
    final ts = _sw.elapsed, text = message.dartify()?.toString() ?? 'null';
    for (var line in ConsoleToHtml.convert(text)) {
      final element = _log(ts, line);
      final red = element.getElementsByClassName("fail");
      if (red.length == 2) {
        // typical test message looks like:
        //    {mm}:{ss} {+Pass} {~Skip} {-Fail} {Test description} {Info}
        // an error message has 2 red parts:
        //    1. "{-Fail}" with the number of failed tests
        //    2. and "{Info}" = "[E]"
        final info = red.element(1)!.innerText;
        final fail = red.element(0)!.innerText;
        final error = -(int.tryParse(fail.replaceAll(' ', '')) ?? 0);
        if (info.contains('[E]') && error > 0 && _errorLines.length < error) {
          _errorLines.add(element);
          _errors += 1;
        }
      }
    }
    if (_scrollToEnd) {
      _forceScroll = true;
      _div.scrollTo(0.toJS, _div.scrollHeight);
    }
  }

  void clear() {
    _errorLines.clear();
    _errors = 0;
    _showError(null);
    _div.innerHTML = ''.toJS;
    _scrollToEnd = true;
    _forceScroll = true;
  }
}

extension on HTMLCollection {
  HTMLElement? element(int idx) => item(idx) as HTMLElement?;
}
