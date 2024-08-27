typedef BufferedItem<T> = ({T? item, Object? err, StackTrace? st});

class EventBuffer<T> {
  EventBuffer(this._process);

  final void Function(BufferedItem<T>) _process;

  final _buffer = <BufferedItem<T>>[];

  var _pauses = 0;

  bool get isActive => _pauses > 0;

  void add(T item) {
    _buffer.add((item: item, err: null, st: null));
  }

  void addError(Object err, StackTrace? st) {
    _buffer.add((item: null, err: err, st: st));
  }

  void pause() {
    _pauses++;
  }

  void resume() {
    if (_pauses == 1) {
      _buffer.forEach(_process);
      _buffer.clear();
    }
    if (_pauses > 0) {
      _pauses--;
    }
  }
}