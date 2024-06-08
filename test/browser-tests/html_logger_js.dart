import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'console_to_html.dart';

final jsobj = context['Object'];

class HtmlLogger {
  HtmlLogger(this._div) {
    _div.onScroll.listen(_onScroll);
    _sw.start();
  }

  static final _formatter = ConsoleToHtml();

  final Stopwatch _sw = Stopwatch();
  final DivElement _div;

  bool _scrollToEnd = true;
  bool _forceScroll = false;

  void _onScroll(Event scrollEvent) {
    if (!_forceScroll) {
      final prevScrollToEnd = _scrollToEnd;
      _scrollToEnd = (_div.scrollHeight - _div.scrollTop) <= _div.clientHeight;
      if (_scrollToEnd != prevScrollToEnd) {
        window.console.log('_scrollToEnd = $_scrollToEnd');
      }
    } else {
      _forceScroll = false;
    }
  }

  void _log(Duration ts, String message, {bool replaceLastLine = false}) {
    if (message.isNotEmpty) {
      message = '[$ts] $message';
    }
    if (replaceLastLine && _div.childNodes.isNotEmpty) {
      _div.childNodes.last.remove();
    }
    _div.append(
      document.createElement('SPAN')..innerHtml = '$message<BR>',
    );
  }

  void print(String message) {
    final ts = _sw.elapsed;
    for (var line in _formatter.convert(message)) {
      _log(ts, line);
    }
    if (_scrollToEnd) {
      _forceScroll = true;
      _div.scrollTo(0, _div.scrollHeight);
    }
  }

  void clear() {
    _div.innerHtml = '';
    _scrollToEnd = true;
  }

  Future pause(String message, {required int seconds}) async {
    final waitTime = Duration(seconds: seconds);
    final timerPeriod = Duration(milliseconds: 100);
    final sw = Stopwatch();
    final timer = Timer.periodic(timerPeriod, (timer) {
      final remaining = Duration(
        microseconds: waitTime.inMicroseconds - sw.elapsedMicroseconds,
      );
      _log(
        _sw.elapsed,
        message.replaceAll('@countdown', remaining.toString()),
        replaceLastLine: sw.isRunning,
      );
      sw.start();
    });
    await Future.delayed(waitTime);
    timer.cancel();
  }
}
