import 'package:squadron/squadron.dart';

const oneCpu = ConcurrencySettings.oneCpuThread;
const threeCpu = ConcurrencySettings.threeCpuThreads;
const oneIo = ConcurrencySettings.oneIoThread;
const twoIo = ConcurrencySettings.twoIoThreads;

const small = ConcurrencySettings(
  minWorkers: 2,
  maxWorkers: 2,
  maxParallel: 2,
);

const medium = ConcurrencySettings(
  minWorkers: 2,
  maxWorkers: 5,
  maxParallel: 3,
);
