class WorkerMonitor {
  WorkerMonitor(this._terminate);

  final void Function() _terminate;
  bool _terminationRequested = false;
  int _executing = 0;

  void begin() {
    _executing++;
  }

  void done() {
    _executing--;
    if (_terminationRequested && _executing == 0) {
      _terminate();
    }
  }

  void terminate() {
    if (_executing == 0) {
      _terminate();
    } else {
      _terminationRequested = true;
    }
  }
}
