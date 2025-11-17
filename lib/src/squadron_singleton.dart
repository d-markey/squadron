import '_impl/xplat/_platform.dart'
    if (dart.library.io) '_impl/native/_platform.dart'
    if (dart.library.html) '_impl/web/_platform.dart'
    if (dart.library.js) '_impl/web/_platform.dart'
    if (dart.library.js_interop) '_impl/web/_platform.dart' as impl;
import 'converters/converter.dart';

String get threadId => impl.threadId;

class Squadron {
  Squadron._();

  /// Gets the current platform type.
  static final platformType = impl.getPlatformType();

  /// Parse [url] and returns the corresponding [Uri].
  ///
  /// On Web platforms, a leading '~' character will be replaced with the
  /// current page's root URL. E.g. '~/workers' from '/path/to/index.html'
  /// will return '/path/to/workers'.
  static Uri uri(String url) => impl.mapUrl(url);

  static bool disableBrowserCache = false;

  static final identical = impl.isSameInstance;
  static final _platformConverter = impl.getPlatformConverter();
  static Converter _converter = _platformConverter;

  /// Gets the current converter.
  static Converter get converter => _converter;

  /// Sets the current converter. If [value] is `null`, the default converter
  /// will be restored. If the converter was updated, handlers registered with
  /// [onConverterChanged] will be notified of the change.
  static set converter(Converter? value) {
    value ??= _platformConverter;
    if (_converter != value) {
      _converter = value;
      for (var handler in _converterChangeHandlers.values) {
        try {
          handler();
        } catch (_) {
          // ignore
        }
      }
    }
  }

  static final _converterChangeHandlers = <Object, void Function()>{};

  /// Registers a callback that will be called whenever `converter` is changed.
  /// Returns an object that can be used to unregister the callback by passing
  /// it to [unregisterConverterChanged].
  static Object onConverterChanged(void Function() handler) {
    final key = Object();
    _converterChangeHandlers[key] = handler;
    return key;
  }

  /// Unregisters a callback that was registered with [onConverterChanged].
  static void unregisterConverterChanged(Object key) {
    _converterChangeHandlers.remove(key);
  }
}
