import 'dart:async';

import 'package:meta/meta.dart';

import '../../pool/task.dart';
import '../../utils.dart';
import '../native/_debug.dart' if (dart.library.js_interop) '../web/_debug.dart'
    as dbg;

extension on Object? {
  String get objectId => '$runtimeType(${hashCode.hex})';
}

@internal
void $log(String message) => dbg.$log(message);

final _busyControllers = <({StreamController controller, StackTrace st})>[];

@internal
extension ControllerTrackerExt on StreamController {
  void track() {
    final prev = _busyControllers.length;
    _busyControllers.add((controller: this, st: StackTrace.current));
    done.whenComplete(_untrack);
    final cur = _busyControllers.length;
    $log('Started tracking $objectId: $prev > $cur');
  }

  void _untrack() {
    final prev = _busyControllers.length;
    _busyControllers.removeWhere((e) => e.controller == this);
    final cur = _busyControllers.length;
    $log('Stopped tracking $objectId: $prev > $cur');
  }

  static int get pendingControllers => _busyControllers.length;
}

final _busyFutures = <({Future future, StackTrace st})>[];

@internal
extension FutureTrackerExt on Future {
  void track() {
    final prev = _busyFutures.length;
    _busyFutures.add((future: this, st: StackTrace.current));
    whenComplete(_untrack);
    final cur = _busyFutures.length;
    $log('Started tracking $objectId: $prev > $cur');
  }

  void _untrack() {
    final prev = _busyFutures.length;
    _busyFutures.removeWhere((e) => e.future == this);
    final cur = _busyFutures.length;
    $log('Stopped tracking $objectId: $prev > $cur');
  }

  static int get pendingControllers => _busyControllers.length;
}

final _busyTasks = <({Task task, StackTrace st})>[];

@internal
extension TaskTracker on Task {
  void track() {
    final prev = _busyTasks.length;
    _busyTasks.add((task: this, st: StackTrace.current));
    done.whenComplete(_untrack);
    final cur = _busyTasks.length;
    $log('Started tracking $objectId - pending tasks: $prev > $cur');
  }

  void _untrack() {
    final prev = _busyTasks.length;
    _busyTasks.removeWhere((e) => e.task == this);
    final cur = _busyTasks.length;
    $log('Stopped tracking $objectId - pending tasks: $prev > $cur');
  }

  static int get pendingTasks => _busyTasks.length;
}
