final _latestUPDEpoch = DateTime.utc(2020, 02, 02); // universal palindrome date

int microsecTimeStamp([DateTime? time]) =>
    (time ?? DateTime.now()).toUtc().difference(_latestUPDEpoch).inMicroseconds;

DateTime? fromMicrosecTimeStamp(int? microsecs) => (microsecs == null)
    ? null
    : _latestUPDEpoch.add(Duration(microseconds: microsecs));

extension FutureExt on Future {
  Future<void> ignore() async {
    try {
      final _ = await this;
    } catch (_) {
      /* ignore */
    }
  }
}
