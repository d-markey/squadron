// import 'dart:async';

// import 'package:cancelation_token/cancelation_token.dart';

// import '../../pool/worker_pool.dart';
// import '../../tokens/_cancelation_token_ref.dart';
// import '../../tokens/_squadron_cancelation_token.dart';
// import '../../worker/worker_request.dart';
// import '../../worker_service.dart';
// import '_task.dart';

// /// Each platform worker will instantiate a [WorkerMonitor] responsible for
// /// handling cancelation requests. Worker tasks in Squadron may be canceled in
// /// two ways: with a [CancelationToken], giving worker services the chance to
// /// handle cancelation requests gracefully, or without a [CancelationToken]
// /// via [WorkerPool.cancel] or [Task.cancel].
// class WorkerMonitor {
//   /// Constructs a new [WorkerMonitor]. The [_terminate] callback will be called
//   /// by [WorkerMonitor.terminate]. This callback should contain code to
//   /// shutdown the platform worker and release resources.
//   WorkerMonitor(this._terminate);

//   final SquadronCallback _terminate;
//   bool _terminationRequested = false;
//   int _executing = 0;

//   ServiceInstaller? _installer;

//   final _cancelTokens = <String, CancelationTokenReference>{};

//   CancelationTokenReference _getTokenRef(SquadronCancelationToken? token) =>
//       (token == null)
//           ? CancelationTokenReference.noToken
//           : _cancelTokens.putIfAbsent(
//               token.id, () => CancelationTokenReference(token.id));

//   /// Starts monitoring execution of this [request]. If the request contains a cancelation token, it
//   /// is overridden with a [CancelationTokenReference] and this reference is returned to the sender.
//   /// Otherwise, returns [CancelationTokenReference.noToken].
//   CancelationTokenReference begin(WorkerRequest request) {
//     _executing++;
//     final token = _getTokenRef(request.cancelToken);
//     token.usedBy(request);
//     return token;
//   }

//   Map<int, SquadronCallback>? _streamCancelers;
//   int _streamId = 0;

//   /// Assigns a stream ID to the stream canceler callback and registers the callback.
//   int registerStreamCanceler(SquadronCallback canceler) {
//     final streamId = ++_streamId;
//     (_streamCancelers ??= <int, SquadronCallback>{})[streamId] = canceler;
//     return streamId;
//   }

//   /// Unregisters the stream canceled callback associated to the [streamId].
//   void unregisterStreamCanceler(int streamId) {
//     final canceler = _streamCancelers?[streamId];
//     if (canceler != null) {
//       _streamCancelers?.remove(streamId);
//     }
//   }

//   /// Updates a [token] via the corresponding [CancelationTokenReference].
//   void updateToken(SquadronCancelationToken token) =>
//       _getTokenRef(token).update(token);

//   /// Cancels a stream via the corresponding [streamId].
//   void cancelStream(int streamId) => _streamCancelers?[streamId]?.call();

//   /// Stops monitoring execution and releases the [tokenRef].
//   void done(CancelationTokenReference tokenRef) {
//     tokenRef.release();
//     if (tokenRef.refCount == 0) {
//       _cancelTokens.remove(tokenRef.id);
//     }
//     _executing--;
//     if (_terminationRequested && _executing == 0) {
//       _shutdown();
//     }
//   }

//   /// Installs the service if it implements [ServiceInstaller].
//   FutureOr<void> install(WorkerService service) {
//     if (service is ServiceInstaller) {
//       _installer = service as ServiceInstaller;
//       return _installer!.install();
//     }
//   }

//   /// Uninstalls the service if it implements [ServiceInstaller].
//   FutureOr<void> _uninstall(ServiceInstaller? installer) {
//     if (installer != null) {
//       try {
//         var res = installer.uninstall();
//         if (res is Future<void>) {
//           res = res.onError((error, stackTrace) => {/* swallow excepions */});
//         }
//         return res;
//       } catch (ex) {/* swallow exceptions*/}
//     }
//   }

//   /// Terminates the worker monitored by this instance if there is no pending execution. Otherwise, marks
//   /// the worker as terminating and termination will be effective when all pending executions are completed.
//   void terminate() {
//     if (_executing == 0) {
//       _shutdown();
//     } else {
//       _terminationRequested = true;
//     }
//   }

//   void _shutdown() {
//     final uninstall = _uninstall(_installer);
//     if (uninstall is Future) {
//       uninstall.whenComplete(_terminate);
//     } else {
//       _terminate();
//     }
//   }
// }
