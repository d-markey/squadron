import '../squadron_singleton.dart';
import '../typedefs.dart';
import 'converter.dart';
import 'lazy_in_place_list.dart';
import 'lazy_in_place_map.dart';
import 'serialization_context.dart';

class ContextAwareConverter extends Converter {
  ContextAwareConverter([Converter? converter])
      : _converter = converter ?? Squadron.converter;

  final Converter _converter;
  // use Squadron.identical to handle JS objects
  final _arguments = SerializationContext(Squadron.identical);

  // non-nullable value
  @override
  Cast<T> value<T extends Object>() {
    final op = _converter.value<T>();
    if (Converter.isNumber<T>() || Converter.isIdentity<T>(op)) {
      // no context needed for numbers / identity converters
      return op;
    }
    return (dynamic x) {
      x as Object;
      var ref = _arguments.getReference<T>(x);
      if (ref != null) return ref;
      ref = op(x);
      _arguments.setReference(x, ref);
      return ref;
    };
  }

  // list
  @override
  Cast<List<T>> list<T extends Object>([Cast<T>? cast]) {
    final op = cast ?? value<T>();
    if (Converter.isIdentity<T>(op)) {
      final toList = _converter.list<T>(); // elements will be cast
      return (dynamic x) {
        var ref = _arguments.getReference<List<T>>(x);
        if (ref != null) return ref;
        ref = toList(x);
        _arguments.setReference(x, ref);
        return ref;
      };
    } else {
      return (dynamic x) {
        var ref = _arguments.getReference<List<T>>(x);
        if (ref != null) return ref;
        ref = LazyInPlaceList(x, op); // elements will be converted upon access
        _arguments.setReference(x, ref);
        return ref;
      };
    }
  }

  @override
  Cast<List<T?>> nlist<T extends Object>([Cast<T>? cast]) {
    final op = cast ?? value<T>();
    if (Converter.isIdentity<T>(op)) {
      final toList = _converter.nlist<T>(); // elements will be cast
      return (dynamic x) {
        var ref = _arguments.getReference<List<T?>>(x);
        if (ref != null) return ref;
        ref = toList(x);
        _arguments.setReference(x, ref);
        return ref;
      };
    } else {
      final nop = Converter.allowNull(op);
      return (dynamic x) {
        var ref = _arguments.getReference<List<T?>>(x);
        if (ref != null) return ref;
        ref = LazyInPlaceList(x, nop); // elements will be converted upon access
        _arguments.setReference(x, ref);
        return ref;
      };
    }
  }

  // set
  @override
  Cast<Set<T>> set<T extends Object>([Cast<T>? cast]) {
    final op = cast ?? value<T>();
    if (Converter.isIdentity<T>(op)) {
      final toSet = _converter.set<T>(); // elements will be cast
      return (dynamic x) {
        var ref = _arguments.getReference<Set<T>>(x);
        if (ref != null) return ref;
        ref = toSet(x);
        _arguments.setReference(x, ref);
        return ref;
      };
    } else {
      return (dynamic x) {
        var ref = _arguments.getReference<Set<T>>(x);
        if (ref != null) return ref;
        ref = <T>{}; // TODO: implement a lazy set?
        _arguments.setReference(x, ref);
        ref.addAll((x as Iterable).map(op));
        return ref;
      };
    }
  }

  @override
  Cast<Set<T?>> nset<T extends Object>([Cast<T>? cast]) {
    final op = cast ?? value<T>();
    if (Converter.isIdentity<T>(op)) {
      final toSet = _converter.nset<T>(); // elements will be cast
      return (dynamic x) {
        var ref = _arguments.getReference<Set<T?>>(x);
        if (ref != null) return ref;
        ref = toSet(x);
        _arguments.setReference(x, ref);
        return ref;
      };
    } else {
      final nop = Converter.allowNull(op);
      return (dynamic x) {
        var ref = _arguments.getReference<Set<T?>>(x);
        if (ref != null) return ref;
        ref = <T?>{}; // TODO: implement a lazy set?
        _arguments.setReference(x, ref);
        ref.addAll((x as Iterable).map(nop));
        return ref;
      };
    }
  }

  // map
  @override
  Cast<Map<K, V>> map<K extends Object, V extends Object>(
      {Cast<K>? kcast, Cast<V>? vcast}) {
    final kop = kcast ?? value<K>();
    final vop = vcast ?? value<V>();
    if (Converter.isIdentity<K>(kop) && Converter.isIdentity<V>(vop)) {
      final toMap = _converter.map<K, V>(); // elements will be cast
      return (dynamic x) {
        var ref = _arguments.getReference<Map<K, V>>(x);
        if (ref != null) return ref;
        ref = toMap(x);
        _arguments.setReference(x, ref);
        return ref;
      };
    } else if (Converter.isIdentity(kop)) {
      return (dynamic x) {
        var ref = _arguments.getReference<Map<K, V>>(x);
        if (ref != null) return ref;
        ref = LazyInPlaceMap(x, vop); // elements will be converted upon access
        _arguments.setReference(x, ref);
        return ref;
      };
    } else {
      return (dynamic x) {
        var ref = _arguments.getReference<Map<K, V>>(x);
        if (ref != null) return ref;
        ref = <K, V>{}; // TODO: implements a lazy map with convertible keys?
        _arguments.setReference(x, ref);
        ref.addEntries(
          (x as Map).entries.map((e) => MapEntry(kop(e.key), vop(e.value))),
        );
        return ref;
      };
    }
  }

  @override
  Cast<Map<K, V?>> nmap<K extends Object, V extends Object>(
      {Cast<K>? kcast, Cast<V>? vcast}) {
    final kop = kcast ?? value<K>();
    final vop = vcast ?? value<V>();
    if (Converter.isIdentity<K>(kop) && Converter.isIdentity<V>(vop)) {
      final toMap = _converter.nmap<K, V>(); // elements will be cast
      return (dynamic x) {
        var ref = _arguments.getReference<Map<K, V?>>(x);
        if (ref != null) return ref;
        ref = toMap(x);
        _arguments.setReference(x, ref);
        return ref;
      };
    } else if (Converter.isIdentity(kop)) {
      final nvop = Converter.allowNull(vop);
      return (dynamic x) {
        var ref = _arguments.getReference<Map<K, V?>>(x);
        if (ref != null) return ref;
        ref = LazyInPlaceMap(x, nvop); // elements will be converted upon access
        _arguments.setReference(x, ref);
        return ref;
      };
    } else {
      final nvop = Converter.allowNull(vop);
      return (dynamic x) {
        var ref = _arguments.getReference<Map<K, V?>>(x);
        if (ref != null) return ref;
        ref = <K, V?>{}; // TODO: implements a lazy map with convertible keys?
        _arguments.setReference(x, ref);
        ref.addEntries(
          (x as Map).entries.map((e) => MapEntry(kop(e.key), nvop(e.value))),
        );
        return ref;
      };
    }
  }
}
