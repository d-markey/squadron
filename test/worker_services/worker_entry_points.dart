import '../sample_vm_workers/worker_entry_points.dart'
    if (dart.library.js) '../sample_js_workers/worker_entry_points.dart'
    if (dart.library.html) '../sample_js_workers/worker_entry_points.dart';

final _entryPoints = <String, dynamic>{};

class EntryPoints {
  static dynamic _get(String key) {
    if (_entryPoints.isEmpty) {
      setEntryPoints();
    }
    return _entryPoints[key];
  }

  static Iterable<dynamic> get entryPoints {
    if (_entryPoints.isEmpty) {
      setEntryPoints();
    }
    return _entryPoints.values;
  }

  static dynamic get bitcoin => _get('bitcoin');
  static set bitcoin(dynamic value) => _entryPoints['bitcoin'] = value;

  static dynamic get cache => _get('cache');
  static set cache(dynamic value) => _entryPoints['cache'] = value;

  static dynamic get echo => _get('echo');
  static set echo(dynamic value) => _entryPoints['echo'] = value;

  static dynamic get failing => _get('failing');
  static set failing(dynamic value) => _entryPoints['failing'] = value;

  static dynamic get failingWithMissingCommand =>
      _get('failing_missing_command');
  static set failingWithMissingCommand(dynamic value) =>
      _entryPoints['failing_missing_command'] = value;

  static dynamic get invalid => _get('invalid');
  static set invalid(dynamic value) => _entryPoints['invalid'] = value;

  static dynamic get issues => _get('issues');
  static set issues(dynamic value) => _entryPoints['issues'] = value;

  static dynamic get local => _get('local');
  static set local(dynamic value) => _entryPoints['local'] = value;

  static dynamic get piDigits => _get('pi_digits');
  static set piDigits(dynamic value) => _entryPoints['pi_digits'] = value;

  static dynamic get prime => _get('prime');
  static set prime(dynamic value) => _entryPoints['prime'] = value;

  static dynamic get rogue => _get('rogue');
  static set rogue(dynamic value) => _entryPoints['rogue'] = value;

  static dynamic get test => _get('test');
  static set test(dynamic value) => _entryPoints['test'] = value;
}
