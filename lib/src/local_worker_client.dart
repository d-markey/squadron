import 'channel.dart';
import 'local_worker.dart';
import 'worker_request.dart';
import 'worker_service.dart';

/// Base class used to communicate with a [LocalWorker].
///
/// Typically, derived classes should add proxy methods sending [WorkerRequest]s to the worker.
class LocalWorkerClient implements WorkerService {
  /// Create a client for a [LocalWorker]. The [channel] passed to this client must have been obtained by
  /// calling [Channel.share] on the [LocalWorker.channel].
  LocalWorkerClient(this.channel);

  /// The [Channel] to communicate with the [LocalWorker].
  final Channel channel;

  /// Sends a command to the [LocalWorker].
  Future<T> send<T>(int command, List args) =>
      channel.sendRequest<T>(command, args);

  /// Sends a streaming command to the [LocalWorker].
  Stream<T> stream<T>(int command, List args) =>
      channel.sendStreamingRequest<T>(command, args);

  /// Local worker clients do not need an [operations] map.
  @override
  final Map<int, CommandHandler> operations = WorkerService.noOperations;
}
