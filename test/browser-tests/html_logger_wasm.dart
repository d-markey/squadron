import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

import 'console_to_html.dart';

class HtmlLogger {
  HtmlLogger(this._div) {
    _div.onscroll = _onScroll.toJS;
    _sw.start();
  }

  static final _formatter = ConsoleToHtml();

  final Stopwatch _sw = Stopwatch();
  final HTMLDivElement _div;

  bool _scrollToEnd = true;
  bool _forceScroll = false;

  void _onScroll(Event scrollEvent) {
    if (!_forceScroll) {
      final prevScrollToEnd = _scrollToEnd;
      _scrollToEnd = (_div.scrollHeight - _div.scrollTop) <= _div.clientHeight;
      if (_scrollToEnd != prevScrollToEnd) {
        console.log('_scrollToEnd = $_scrollToEnd'.toJS);
      }
    } else {
      _forceScroll = false;
    }
  }

  void _log(Duration ts, String message, {bool replaceLastLine = false}) {
    if (message.isNotEmpty) {
      message = '[$ts] $message';
    }
    if (replaceLastLine && _div.childNodes.length > 0) {
      _div.removeChild(_div.childNodes.item(_div.childNodes.length - 1)!);
    }
    _div.appendChild(
      document.createElement('SPAN')..innerHTML = '$message<BR>'.toJS,
    );
  }

  void print(String message) {
    final ts = _sw.elapsed;
    for (var line in _formatter.convert(message)) {
      _log(ts, line);
    }
    if (_scrollToEnd) {
      _forceScroll = true;
      _div.scrollTo(0.jsify()!, _div.scrollHeight);
    }
  }

  void clear() {
    _div.innerHTML = ''.toJS;
    _scrollToEnd = true;
  }

  Future pause(String message, {required int seconds}) async {
    final waitTime = Duration(seconds: seconds);
    final timerPeriod = Duration(milliseconds: 100);
    final sw = Stopwatch();
    final timer = Timer.periodic(timerPeriod, (timer) {
      final remaining = Duration(
          microseconds: waitTime.inMicroseconds - sw.elapsedMicroseconds);
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
