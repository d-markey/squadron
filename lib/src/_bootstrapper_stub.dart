import 'squadron.dart';
import 'worker_exception.dart';
import 'worker_request.dart';
import 'worker_response.dart';
import 'worker_service.dart';
import 'cancellation_token.dart';

part '_worker_runner.dart';
part '_worker_monitor.dart';

void bootstrap(WorkerInitializer initializer, Map? command) =>
    throw UnsupportedError('bootstrap() is not supported on this platform.');

Future Function(Map message) buildConnector(Object channelInfo,
    Map<int, CommandHandler>? operations, WorkerInitializer? initializer) {
  return (Map message) =>
      _WorkerRunner.connect(message, channelInfo, operations, initializer);
}

void Function(Map message) buildMessageProcessor(
    Map<int, CommandHandler> operations, _WorkerMonitor monitor) {
  return (Map message) => _WorkerRunner.process(operations, message, monitor);
}

_WorkerMonitor buildMonitor(SquadronCallback terminate) =>
    _WorkerMonitor(terminate);
