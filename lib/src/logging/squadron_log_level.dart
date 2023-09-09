/// Log level constants, compatible with `package:logging`
class SquadronLogLevel {
  SquadronLogLevel._();

  /// Lowest log level
  static const all = 0;

  /// Debug log level
  static const debug = 1;

  /// Finest log level
  static const finest = 300;

  /// Finer log level
  static const finer = 400;

  /// Fine log level
  static const fine = 500;

  /// Config log level
  static const config = 700;

  /// Information log level
  static const info = 800;

  /// Warning log level
  static const warning = 900;

  /// Severe log level
  static const severe = 1000;

  /// Shout log level
  static const shout = 1200;

  /// No logging
  static const off = 2000;

  /// Gets the log level name
  static String getName(int logLevel) {
    if (logLevel < debug) return 'ALL';
    if (logLevel < finest) return 'DEBUG';
    if (logLevel < finer) return 'FINEST';
    if (logLevel < fine) return 'FINER';
    if (logLevel < config) return 'FINE';
    if (logLevel < info) return 'CONFIG';
    if (logLevel < warning) return 'INFO';
    if (logLevel < severe) return 'WARNING';
    if (logLevel < shout) return 'SEVERE';
    if (logLevel < off) return 'SHOUT';
    return 'OFF';
  }
}
