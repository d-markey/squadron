final _latestUPDEpoch = DateTime.utc(2020, 02, 02); // universal palindrome date

int microsecTimeStamp([DateTime? time]) =>
    (time ?? DateTime.now()).toUtc().difference(_latestUPDEpoch).inMicroseconds;

DateTime fromMicrosecTimeStamp(int microsecs) =>
    _latestUPDEpoch.add(Duration(microseconds: microsecs));
