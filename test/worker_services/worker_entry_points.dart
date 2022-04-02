import 'worker_entry_points_stub.dart'
    if (dart.library.js) '../sample_js_workers/worker_entry_points.dart'
    if (dart.library.html) '../sample_js_workers/worker_entry_points.dart'
    if (dart.library.io) '../sample_vm_workers/worker_entry_points.dart';

final _entryPoints = entryPoints;

class EntryPoints {
  static dynamic get bitcoin => _entryPoints['bitcoin'];
  static set bitcoin(dynamic value) => _entryPoints['bitcoin'] = value;

  static dynamic get cache => _entryPoints['cache'];
  static set cache(dynamic value) => _entryPoints['cache'] = value;

  static dynamic get echo => _entryPoints['echo'];
  static set echo(dynamic value) => _entryPoints['echo'] = value;

  static dynamic get failing => _entryPoints['failing'];
  static set failing(dynamic value) => _entryPoints['failing'] = value;

  static dynamic get failingWithMissingCommand =>
      _entryPoints['failing_missing_command'];
  static set failingWithMissingCommand(dynamic value) =>
      _entryPoints['failing_missing_command'] = value;

  static dynamic get invalid => _entryPoints['invalid'];
  static set invalid(dynamic value) => _entryPoints['invalid'] = value;

  static dynamic get local => _entryPoints['local'];
  static set local(dynamic value) => _entryPoints['local'] = value;

  static dynamic get piDigits => _entryPoints['pi_digits'];
  static set piDigits(dynamic value) => _entryPoints['pi_digits'] = value;

  static dynamic get prime => _entryPoints['prime'];
  static set prime(dynamic value) => _entryPoints['prime'] = value;

  static dynamic get rogue => _entryPoints['rogue'];
  static set rogue(dynamic value) => _entryPoints['rogue'] = value;

  static dynamic get sample => _entryPoints['sample'];
  static set sample(dynamic value) => _entryPoints['sample'] = value;
}
