---
name: squadron-marshaling
description: Use when handling custom classes, object serialization, deserialization, and custom marshalers (SquadronMarshaler, GenericMarshaler, MarshalingContext) for cross-platform worker communication in Squadron.
---

# Squadron Custom Class Marshaling Guide

In Squadron, passing base types (`int`, `double`, `String`, `bool`, `null`, nullable variants, `List`, `Map`) between the main thread and worker threads is handled automatically. However, passing custom classes requires serialization/deserialization because thread boundaries (isolates on Native, Web Workers on Web) do not share memory.

*Note on Spelling:* While British English uses **marshalling** (two 'l's), American English uses **marshaling** (one 'l'). Squadron follows the American spelling and uses **`SquadronMarshaler`** (one 'l') in its class names.

## 1. Cross-Platform Constraints & Serialization Approaches
- **Native (VM / Isolates)**: On the VM, marshaling is generally **avoidable**. Dart's Isolate send ports handle many custom object graphs natively via underlying VM serialization/copying.
- **Web (Web Workers)**: Marshaling becomes mandatory and critical on the Web (and even more so in cross-platform code supporting both Web and VM). Web Workers operate over message channels using strict structured cloning where complex custom classes cannot be sent directly unless converted into transferable primitives (like `List`, `Map`, or `JSArrayBuffer`).

When passing custom classes across thread boundaries, Squadron provides two primary ways to handle serialization:
- **Approach A**: Implement serialization directly within the custom class (via `marshal()` / `unmarshal()` or standard `toJson()` / `fromJson()`).
- **Approach B**: Implement a dedicated marshaler class via the `SquadronMarshaler` interface. Note that marshaler classes are used as annotations (for service method arguments/return types or on the custom class itself), and as a result **must provide `const` constructors** and be instantiable as `const` instances.

---

## 2. Approach A: Direct Serialization in Custom Classes
You can implement serialization directly within your custom class without writing a separate marshaler class:
- **Dedicated methods**: Implement an instance method `SomeTransferable marshal({MarshalingContext? context})` and a factory constructor or static method `static MyCustomType unmarshal(SomeTransferable transferable, {MarshalingContext? context})`.
- **Standard JSON methods**: `squadron_builder` can also automatically detect and use standard `toJson()` and `fromJson()` methods when present. *(Note: The JSON approach is simple and straightforward, but does not support a `MarshalingContext`, meaning it cannot handle circular references or object identity preservation across complex object graphs).*

### Example: Direct `marshal()` & `unmarshal()`
```dart
import 'package:squadron/squadron.dart';

class TaskItem {
  final String id;
  final String description;

  TaskItem(this.id, this.description);

  // Serialize to a transferable List or Map
  List marshal({MarshalingContext? context}) {
    return [id, description];
  }

  // Deserialize back from the transferable representation
  static TaskItem unmarshal(dynamic transferable, {MarshalingContext? context}) {
    final list = transferable as List;
    return TaskItem(list[0] as String, list[1] as String);
  }
}
```

### Example: Standard `toJson()` & `fromJson()`
```dart
class TaskItemJson {
  final String id;
  final String description;

  TaskItemJson(this.id, this.description);

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
      };

  factory TaskItemJson.fromJson(Map<String, dynamic> json) =>
      TaskItemJson(json['id'] as String, json['description'] as String);
}
```

---

## 3. Approach B: Dedicated Marshalers via the `SquadronMarshaler` Interface
For cleaner separation of concerns, you can implement a separate marshaler class using the `SquadronMarshaler` interface (`GenericMarshaler` & `MarshalingContext`). Because these dedicated marshaler classes are used as annotations (e.g., `@PersonMarshaler()`), they **must have a `const` constructor** and be usable as `const` instances.

To send custom classes across threads via a separate marshaler, implement `SquadronMarshaler<T, S>`:
- `T`: The original custom class type.
- `S`: The transferable / serializable representation type (typically `List` or `Map`).

```dart
abstract class SquadronMarshaler<T, S> {
  const SquadronMarshaler();

  S marshal(T data, [MarshalingContext? context]);
  T unmarshal(S data, [MarshalingContext? context]);
}
```
*Rule:* `unmarshal(marshal(data))` must produce an instance of `T` equivalent to the original `data`. 
* **Important Equivalence Note**: Because marshaling and unmarshaling create a brand-new instance across the thread boundary, `identical(original, unmarshaled)` will **always return `false`**, and the equality operator (`==`) will return `false` unless explicitly overloaded in your class `T`.

### Using `GenericMarshaler` & `MarshalingContext`
For complex object graphs, deep structures, or circular references, Squadron provides `GenericMarshaler` and `MarshalingContext`.
- **`MarshalingContext`**: Tracks object references during serialization and deserialization to prevent infinite loops (e.g., circular graphs or shared references) and preserve object identity within the same payload transfer.

### Example Marshaling Implementation:
```dart
part of 'person.dart';

class PersonMarshaler extends GenericMarshaler<Person> {
  const PersonMarshaler();

  @override
  dynamic marshal(Person data, [MarshalingContext? context]) {
    var res = context?.getReference<List>(data);
    if (res != null) return res;

    res = [
      data.lastName,
      data.firstName,
      data.dateOfBirth,
    ];

    // Register reference before recursing to handle circular references
    context?.setReference(data, res);

    return res;
  }

  @override
  Person unmarshal(dynamic data, [MarshalingContext? context]) {
    data as List;
    var res = context?.getReference<Person>(data);
    if (res != null) return res;

    res = Person._(data[0], data[1], data[2]);
    context?.setReference(data, res);

    return res;
  }
}
```

---

## 4. Alternative Optimization: Extension Types over `List` or `Map`
To completely avoid the cost and complexity of writing custom marshalers for custom data structures, you can implement business objects as **Dart extension types** wrapping a `List` or `Map`.

Because extension types are statically erased at runtime back to their underlying representation (`List` or `Map`), they are passed across thread boundaries natively without needing any serialization or custom marshaler.

### Example Extension Type (`person_ex.dart`):
```dart
extension type PersonEx(Map<String, dynamic> _data) {
  PersonEx({required String lastName, required String firstName, int? age})
      : this({'lastName': lastName, 'firstName': firstName, 'age': age});

  String get lastName => _data['lastName'] as String;
  String get firstName => _data['firstName'] as String;
  int? get age => _data['age'] as int?;
}
```
*Note:* Do **not** implement or implement-forward the underlying `Map` (e.g., omit `implements Map<String, dynamic>`), as doing so would expose raw map mutation methods that could violate object immutability (e.g., allowing unintended writes to keys).

### Trade-offs & Limitations:
- **Pros**: Zero runtime overhead for marshaling; works seamlessly across all platforms out-of-the-box as a standard `Map`.
- **Cons / Costs**: 
  - Minor performance overhead when accessing members (dictionary lookups / key checks in the underlying `Map`).
  - Extension types do not support traditional class inheritance trees or polymorphism.
  - **Cannot override `==` or `hashCode`** in extension types (value equality must be handled via helper functions or property comparisons).

---

## 5. Performance Optimization: Platform-Specific Marshalers
Because Native (VM) isolates can natively pass and copy many object types while Web Workers require strict serialization, you can optimize performance by implementing **platform-specific marshalers**:
- Use `GenericMarshaler<T>` (or a custom serializer) on Web.
- Use `IdentityMarshaler<T>` on the VM/Native platform (which passes objects directly with zero overhead).

You can export or alias the correct marshaler conditionally using Dart's `export ... if (dart.library.js_interop) ...`:

### Example Conditional Marshaler Export (`person_marshaler.dart`):
```dart
export 'person_marshaler_stub.dart'
    if (dart.library.io) 'person_marshaler_vm.dart'
    if (dart.library.js_interop) 'person_marshaler_web.dart';
```

- **`person_marshaler_stub.dart`** (fallback / analyzer stub):
  ```dart
  import 'package:squadron/squadron.dart';
  import 'person.dart';

  abstract class PersonMarshaler implements SquadronMarshaler<Person, dynamic> {
    const PersonMarshaler();
  }
  ```

- **`person_marshaler_vm.dart`** (Native / VM platform):
  ```dart
  import 'package:squadron/squadron.dart';
  import 'person.dart';

  // Zero-overhead identity marshaler on VM
  typedef PersonMarshaler = IdentityMarshaler<Person>;
  ```

- **`person_marshaler_web.dart`** (Web platform):
  ```dart
  import 'package:squadron/squadron.dart';
  import 'person.dart';

  // Full serialization marshaler on Web
  class PersonMarshaler extends GenericMarshaler<Person> {
    const PersonMarshaler();
    // ... marshal / unmarshal implementations for Web ...
  }
  ```

---

## 6. Registering Marshalers (`@SquadronMethod` & `@MyCustomTypeMarshaler`)
To instruct `squadron_builder` to marshal custom parameters or return types, `MyCustomType` parameters must be decorated with a marshaler (ensuring marshalers provide a `const` constructor and can be instantiated as `const` instances):

```dart
@SquadronMethod()
@PersonMarshaler()
Future<Person> processPerson(@PersonMarshaler() Person person) async {
  // ...
}
```

**Alternative (Global Registration):**
Instead of decorating parameters individually on every method, you can decorate the custom class itself with its marshaler. When decorated this way, `squadron_builder` automatically uses the registered marshaler everywhere the custom type is required across service methods:

```dart
@PersonMarshaler()
class Person {
  // ...
}

@SquadronService()
class MyService {
  @SquadronMethod()
  Future<Person> processPerson(Person person) async {
    // Automatically uses PersonMarshaler
    return person;
  }
}
```
