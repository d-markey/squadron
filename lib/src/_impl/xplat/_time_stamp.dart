int microsecTimeStamp([DateTime? time]) =>
    time?.microsecondsSinceEpoch ?? DateTime.now().microsecondsSinceEpoch;

DateTime? fromMicrosecTimeStamp(int? microsecs) =>
    (microsecs == null) ? null : DateTime.fromMicrosecondsSinceEpoch(microsecs);
