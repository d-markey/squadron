import 'package:squadron/squadron.dart';

Map<Type, Worker Function([dynamic arg])> get workerBuilders =>
    throw Exception('Unsupported platform');

T getWorker<T>([dynamic arg]) => workerBuilders[T]!(arg) as T;
