final _sqEpoch = DateTime.utc(2020, 1, 1);

int microsecTimeStamp() =>
    DateTime.now().toUtc().difference(_sqEpoch).inMicroseconds;
