import 'worker.dart';

abstract class WorkerService {
  Map<int, CommandHandler> get operations;
}
