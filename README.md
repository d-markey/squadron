<table><tr>
<td valign="top">
  <img src="https://raw.githubusercontent.com/d-markey/squadron/main/squadron_logo.svg" width="120" alt="Squadron logo" />
</td>
<td>

## **Squadron - Multithreading and worker pools in Dart**

Offload CPU-bound and long running tasks and give your apps some air!

Works everywhere: desktop, server, device, browser.

Supports native, JavaScript & Web Assembly platforms.

[![Pub Package](https://img.shields.io/pub/v/squadron)](https://pub.dev/packages/squadron)
[![Dart Platforms](https://badgen.net/pub/dart-platform/squadron)](https://pub.dev/packages/squadron)
[![Flutter Platforms](https://badgen.net/pub/flutter-platform/squadron)](https://pub.dev/packages/squadron)

[![License](https://img.shields.io/github/license/d-markey/squadron)](https://github.com/d-markey/squadron/blob/master/LICENSE)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Dart Style](https://img.shields.io/badge/style-lints-40c4ff)](https://pub.dev/packages/lints)
[![Pub Points](https://img.shields.io/pub/points/squadron)](https://pub.dev/packages/squadron/score)
[![Likes](https://img.shields.io/pub/likes/squadron)](https://pub.dev/packages/squadron/score)
[![Popularity](https://img.shields.io/pub/popularity/squadron)](https://pub.dev/packages/squadron/score)

[![Last Commit](https://img.shields.io/github/last-commit/d-markey/squadron?logo=git&logoColor=white)](https://github.com/d-markey/squadron/commits)
[![Dart Workflow](https://github.com/d-markey/squadron/actions/workflows/dart.yml/badge.svg?logo=dart)](https://github.com/d-markey/squadron/actions/workflows/dart.yml)
[![Code Lines](https://img.shields.io/badge/dynamic/json?color=blue&label=code%20lines&query=%24.linesValid&url=https%3A%2F%2Fraw.githubusercontent.com%2Fd-markey%2Fsquadron%2Fmain%2Fcoverage.json)](https://github.com/d-markey/squadron/tree/main/coverage/html)
[![Code Coverage](https://img.shields.io/badge/dynamic/json?color=blue&label=code%20coverage&query=%24.lineRate&suffix=%25&url=https%3A%2F%2Fraw.githubusercontent.com%2Fd-markey%2Fsquadron%2Fmain%2Fcoverage.json)](https://github.com/d-markey/squadron/tree/main/coverage/html)

</td>
</tr></table>

[View latest documentation on GitHub](https://github.com/d-markey/squadron/blob/main/README.md)

[Test Console available on GitHub Pages](https://d-markey.github.io/squadron/test-console/)

## <a name="getting_started"></a>Getting Started

1. Update your `pubspec.yaml` file to add dependencies to **[Squadron][pub_squadron]** and **[squadron_builder][pub_squadron_builder]** + [build_runner](https://pub.dev/packages/build_runner):

```yaml
dependencies:
  squadron: ^7.0.0
  # ...

dev_dependencies:
  build_runner:
  squadron_builder: ^7.0.0
  # ...
```

2. Have dart download and install the dependencies:

```bash
dart pub get
```

## <a name="implement"></a>Implementing a Service

Create a class containing the code you intend to run in a dedicated thread and make sure you provide `squadron` annotations:

* use **`SquadronService`** for the class;

* use **`SquadronMethod`** for the methods you want to expose.

Service methods must return a `Future<T>`, a `FutureOr<T>` or a `Stream<T>`.

```dart
// file hello_world.dart
import 'dart:async';

import 'package:squadron/squadron.dart';

import 'hello_world.activator.g.dart';
part 'hello_world.worker.g.dart';

@SquadronService(baseUrl: '~/workers', targetPlatform: TargetPlatform.vm | TargetPlatform.web)
// or @SquadronService(baseUrl: '~/workers', targetPlatform: TargetPlatform.all)
base class HelloWorld {
  @SquadronMethod()
  FutureOr<String> hello([String? name]) {
    name = name?.trim() ?? 'World';
    return 'Hello, $name!';
  }
}
```

## <a name="build"></a>Generating the Worker and WorkerPool code

Have [squadron_builder][pub_squadron_builder] generate the code with the following command line:

```bash
dart run build_runner build
```

This command will create the worker and worker pool from your service: `HelloWorldWorker` and `HelloWorldWorkerPool`.

Workers and worker pools generated by [squadron_builder][pub_squadron_builder] implement the same interface as the original service and proxy all method calls to an instance of the service running in its own thread.

## <a name="run"></a>Spawning a Worker

In your program, you can instantiate a `Worker` (or a `WorkerPool` if you need more threads) and use it just as you would use your original service.

**Make sure you stop the workers and pools before exiting** your program. Failure to do so will let your program run forever.

```dart
// file main.dart
import 'package:squadron/squadron.dart';

import 'hello_world.dart';

void main() async {
  final worker = HelloWorldWorker();
  try {
    // Squadron will start the worker for you so you don't have to call worker.start()
    final message = await worker.hello();
    print(message);
  } finally {
    // make sure the worker is stopped when the program terminates
    worker.stop();
  }
}
```

## <a name="web"></a>Building for the Web

**You must compile your code to JavaScript or Web Assembly** if your app is designed to run in a browser.

```bash
dart compile js ".\src\lib\hello_world.web.g.dart" -o "..\web\workers\hello_world.web.g.dart.js"
dart compile wasm ".\src\lib\hello_world.web.g.dart" -o "..\web\workers\hello_world.web.g.dart.wasm"
```
When compiling to only one of Javascript or Web Assembly, you must make sure your service `@SquadronService()` annotation only references the corresponding `TargetPlatform.js` or `TargetPlatform.wasm`.

You can also compile for both targets: at runtime, Squadron will use the workers matching your app's platform. In that case, make sure your service annotation targets platforms `TargetPlatform.js | TargetPlatform.wasm` or shortcut `TargetPlatform.web`.

## <a name="constraints"></a>Multithreading Constraints

There are a few constraints to multithreading in Dart:

* **Dart threads do not share memory**: values passed from one side to the other will typically be cloned. Depending on the implementation, this can impact performance.

* **Service methods arguments and return values need to cross thread-boundaries**: on Web platforms, the Dart runtime delegates this to the browser which is not aware of Dart's type-system. Extra-work is necessary to recover strongly-typed data on the receiving-end.

Data sent through Squadron are handled as `dynamic` types: to recover strong types and guarantee type-safety in your code, Squadron provides `Converter`s to "convert" data on the receiving-end:

* native platforms use a `CastConverter` that will try its best to just cast data and avoid inspecting collection contents. This may not always be possible and it could impact performance.

* on Web platforms, objects sent to/from a Web Worker leave Dart's realm when they go through the browser's `postMessage()` function, losing their Dart type in the process. They must therefore re-enter Dart's type-system on the receiving end. Squadron provides a `CastConverter` (converting data as well as items in `List`/`Set`/`Map` objects) and a `NumConverter` (adding special handling for `int`/`double` values) depending on the underlying runtime (JavaScript or Web Assembly).

### <a name="types_native"></a>Native Platforms

On native platforms, it is generally safe to not bother about custom types and cloning. The Dart VM will take care of copying data when necessary, optimize data-transfer when possible (eg. `String`s do not require copying), and object types are retained.

There are a few constraints on what type of data can be transferred, please refer to [SendPort.send()](https://api.dart.dev/dart-isolate/SendPort/send.html) documentation for more information.

On native platforms, Squadron uses a default `CastConverter` that will try to simply cast data on the receiving end.

However, when there are nested conversions (eg. `list<T>(nestedConversion)`), casting is only possible when the nested conversion is the identity (`(x) => x as T`). In other situations, the conversion must be applied and this could impact performance in complex data structures (such as maps / lists). See [Optimizing Conversions](#optimizing-conversions) for more information.

### <a name="types_web"></a>Web Platforms

Web platforms have stronger constraints when it comes to transferable objects: for more information, please refer to [Transferable objects](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Transferable_objects) documentation or the [HTML specification for transferable objects](https://html.spec.whatwg.org/multipage/structured-data.html#transferable-objects). There may also be differences between browser flavors and versions.

On Web plaforms, Squadron uses a default `CastConverter` (JavaScript runtime) or `NumConverter` (Web Assembly runtime). One of the key differences between Dart, Web Assembly and JavaScript is number handling: JavaScript only really knows `double` numbers whereas Dart and Web Assembly support `int` and `double` as different types. As a result, on JavaScript platforms, [Dart's `int` is actually a subtype of `double`](https://dart.dev/guides/language/numbers#types-and-type-checking) and special care is required when transfering numbers: on Web Assembly platforms, the receiving-end may receive `int` values as `double` and require a conversion back to `int`.

More importantly, custom-types will require marshaling so they can be transferred across worker boundaries. Squadron is not too opinionated and there are various ways to achieve this: eg. using JSON (together with `json_serializer` for instance), by implementing `marshal()`/`unmarshal()` or `toJson()`/`fromJson()` methods in your data classes, or by using [Squadron marshalers](https://pub.dev/documentation/squadron/latest/squadron/SquadronMarshaler-class.html).

Here's an example of a `Person` class, and a Squadron `PersonMarshaler` to serialize/deserialize instances of `Person`:

```dart
class Person {
  Person(this.firstName, this.lastName, this.dateOfBirth);

  String firstName;
  String lastName;
  final DateTime dateOfBirth;
}

class PersonMarshaler implements GenericMarshaler<Person> {
  const PersonMarshaler();

  @override
  dynamic marshal(Person data, [MarshalingContext? context]) => [
    data.firstName,
    data.lastName,
    data.dateOfBirth.millisecondsSinceEpoch,
  ];

  @override
  Person unmarshal(dynamic data, [MarshalingContext? context]) {
    data as List;
    // while the entry produced by `marshal` is an `int`,
    // it could require conversion e.g. with Wasm workers
    // where `int` values are actually transferred as `double`
    final dob = context.converter.value<int>()(data[2]);
    return Person(data[0], data[1], dob);
  }
} 
```

[squadron_builder][pub_squadron_builder] implements proper conversion in and out when generating the code for `PersonServiceWorker`. You only need to apply the marshaler by annotating `Person` parameters and/or return values:

```dart
@SquadronService(baseUrl: '~/workers', targetPlatform: TargetPlatform.web)
base class PersonService {
  @SquadronMethod()
  FutureOr<double> getAge(@PersonMarshaler() Person p) {
    final now = DateTime.now(), dob = p.dateOfBirth;
    final today = DateTime(now.year, now.month, now.day);
    DateTime lastBirthday, nextBirthday;
    lastBirthday = DateTime(today.year, dob.month, dob.day);
    if (lastBirthday.isAfter(today)) {
      nextBirthday = lastBirthday;
      lastBirthday = DateTime(nextBirthday.year - 1, dob.month, dob.day);
    } else {
      nextBirthday = DateTime(lastBirthday.year + 1, dob.month, dob.day);
    }
    final years = lastBirthday.year - dob.year;
    final sinceLast = today.difference(lastBirthday).inDays;
    final toNext = nextBirthday.difference(lastBirthday).inDays;
    return years + sinceLast / toNext;
  }
}
```

Even easier, just annotate the `Person` class with the marshaler!

```dart
@PersonMarshaler()
class Person {
  // ...
}
```

### <a name="conversions"></a>Optimizing Conversions

As stated in a previous paragraph, code designed to run only on native platforms should not worry about data conversion. Because Squadron native workers share the same code and execute in `Isolate`s running in the same Dart VM, they never leave Dart's type-system. Data sent through Squadron is promoted from `dynamic` back to strong-types by simple cast operations.

On Web platforms, things are different because the data was handed over to the browser which doesn't know anything about Dart types:

* `bool` and `String`: casting is enough to re-enter Dart's type system (handled by `CastConverter`).

* `int` and `double`: integers may be received as floating points numbers; in JavaScript runtimes, `int` is a subtype of `double` and casting is enough (handled by `CastConverter`); in Web Assembly runtimes, integer values may be received as a `double` and require conversion back to `int` (handled by `NumConverter`).

* `List`, `Set` and `Map`: these objects are received as `List<dynamic>`, `Set<dynamic>` and `Map<dynamic, dynamic>`. Item, key and value types are systematically lost. Type-casting is not enough and would always fail with a `TypeError`. Additional processing is required from the converter.

To handle collections as efficiencly as possible, converters provided by Squadron optimize the process when the item type is a base type that can be handled by a simple cast. Eg. when a service method works with a `List<String>`, it is received as a `List<dynamic>` and will be "promoted" back to `List<String>` by simply calling `list.cast<String>()` (same for `Set`). For `Map<K, V>` objects where `K` and `V` are base types, the received `Map<dynamic, dynamic>` will be cast back to `Map<K, V>` with `map.cast<K, V>()`. In these scenarios, cast operations are deferred until items are accessed. Dart's static type-safety checks should guarantee success of cast operations.

When collections contain elements that cannot be cast, additional processing is required.

Web Assembly workers requires extra-care: starting from version 7.0, Squadron has implemented custom versions of `package:web`'s `jsify` and `dartify` functions to better work with Squadron's `NumConverter`. This implementation helps handle the `int`/`double` issue (see [issue #55203](https://github.com/dart-lang/sdk/issues/55203)) as well as the stringified-keys issue in `maps` (see [issue #57113](https://github.com/dart-lang/sdk/issues/57113)).

While casting should be enough (and hopefully not too expensive) on VM platform, it will not be the case on Web platforms where performance might be impacted. For instance, when working with large collections or complex structures such as nested lists/maps, the conversion process may require inspecting all list items or map keys & values. It can be optimized in various ways, eg. a large list of integers could be handled via a `Int32List` that will travel to/from workers via a (hopefully efficient) byte buffer.

### <a name="marshaling"></a>Marshaling

Converters only take care of base types (strings, numbers, booleans, lists, maps and sets as well as Dart's typed data and `BigInt`). The default behavior for other types is to simply cast the `dynamic` value to the specified type, whether they're Dart types such as `DateTime` or `Duration`, or custom types that you or a third-party package implemented.

But casting will only work on native Dart VM. On browser platforms, custom objects must be serialized when sent and deserialized when received. Squadron provides `SquadronMarshaler<T, S>` for you to implement your own marshaler:

* `S marshal(T data, [MarshalingContext? context])`: implement this method to serialize an instance of `T` to something that can be transfered, for instance a `List`;

* `T unmarshal(S data, [MarshalingContext? context])`: implement this method to deserialize from `S` and back to `T`.

`unmarshal(marchal(obj))` should produce an instance of `T` that is functionaly equivalent to the original instance `obj`.

For instance, given the following class:

```dart
class Car {
  Car(this.color, this.price, this.engine);

  final String color;
  final double price;
  final Engine engine;
}

enum Engine { gaz, diesel, electric }
```

A marshaler could be implemented as:

```dart
// for use as an annotation
const carMarshaler = CarMarshaler();

class CarMarshaler implements SquadronMarshaler<Car, List> {
  const CarMarshaler();

  List marshal(Car data, [MarshalingContext? context]) => [
      data.color, // color at index 0
      data.price, // price at index 1
      data.engine.index, // engine at index 2
    ];

  Car unmarshal(List data, [MarshalingContext? context]) {
    final price = context.converter.value<double>()(data[1]);
    final engineIndex = context.converter.value<int>()(data[2]);
    return Car(
      data[0],
      price,
      Engine.values[engineIndex]),
    );
  }
}
```

[squadron_builder][pub_squadron_builder] generates code using the marshaler annotation you provide in your service implementation:

```dart
@SquadronService()
class CarService {
  @serviceMethod
  @carMarshaler
  FutureOr<Car?> buy(double cash, String color) { /* ... */ }

  @serviceMethod
  FutureOr<double> sell(@carMarshaler Car car) { /* ... */ }
}
```

Alternatively, if you own the target class, you can also simply annotate it:

```dart
@carMarshaler
class Car {
  // ...
}

@SquadronService()
class CarService {
  @serviceMethod
  FutureOr<Car> buy(double cash, String color) { /* ... */ }

  @serviceMethod
  FutureOr<double> sell(Car car) { /* ... */ }
}
```

If your application is designed to run both on native and Web platforms, it is possible to optimize for VM platforms by providing different marshalers depending on the platform and conditionally import the proper implementation. Eg. on VM platforms, marshalers would mostly be 'no-ops'.

```dart
///////////// file car_marshaler.web.dart /////////////
// for use as an annotation
const carMarshaler = _CarMarshaler();

class _CarMarshaler implements SquadronMarshaler<Car, List> {
  const CarMarshaler();

  List marshal(Car data, [MarshalingContext? context]) => [ /* fields */ ];

  Car unmarshal(List data, [MarshalingContext? context]) => Car(/* arguments */);
}


///////////// file car_marshaler.vm.dart /////////////

// for use as an annotation
// IdentityMarshalers do nothing :)
const carMarshaler = IdentityMarshaler<Car>();


///////////// file car.dart /////////////

import 'car_marshaler.vm.dart'
  if (dart.library.js_interop) 'car_marshaler.web.dart';

@carMarshaler
class Car {
  // ...
}
```

### <a name="marshaling-context"></a>Marshaling Context

Marshalers can work with a `MarshalingContext`. The marshaling context stores results of marshaling/unmarshaling operations and serves the same result if the same instance is un/marshaled again.

**Using a marshaling context guarantees instance identities after transfer.** For instance:

```dart
class Person {
  Person(this.name, [this.father, this.mother]);

  final String name;
  final Person? father;
  final Person? mother;
}

Person father = Person('Dad'), mother = Person('Mom');
Person me = Person('Me', father, mother);
Person sister = Person('Sister', father, mother);
Person brother = Person('Brother', father, mother);
```

Without a marshaling context, sending `me` and `brother` to a Web worker, will result in different instances of `father` and `mother` after un/marshaling. As a result, `identical(me.father, brother.father)` holds true on the sender side, but false on the receiving end. Using a marshaling context, `me.father` and `brother.father` will result in the same instance after un/marshaling.

**Marshaling contexts also allow for cyclical references.** For instance, adding a `children` property to the `Person` class:

```dart
class Person {
  /// ...

  final children = <Person>[];
}

// ...
father.children.addAll([me, brother, sister]);
mother.children.addAll([me, brother, sister]);
```

This creates cyclical references that will fail to marshal unless a marshaling context is used.

Again, Squadron is not opinionated when it comes to serialization: but it will try and support you in as many ways as possible. You keep full control over the way you choose to serialize your custom classes. For instance, you may choose to not send children as full `Person` instances and instead send just some ids or a subset of properties that won't introduce circular dependencies. It's up to you to assess pros and cons and implement your own solution.

For a concrete example, see https://github.com/d-markey/squadron/blob/main/test/worker_services/persons.

## <a name="thanks"></a>Thanks!

* [Saad Ardati](https://github.com/SaadArdati) for his patience and feedback when implementing Squadron into his Flutter application.
* [Martin Fink](https://github.com/martin-robert-fink) for the feedback on Squadron's first `Stream` implementation -- this has resulted in huge progress and a major improvement.
* [Klemen Tusar](https://github.com/techouse) for providing a [sample Chopper JSON decoder](https://hadrien-lejard.gitbook.io/chopper/faq#decoding-json-using-isolates) leveraging Squadron.
* [James O'Leary](https://github.com/jpohhhh) for sponsorship and contribution, very much appreciated.



[pub_squadron]: https://pub.dev/packages/squadron
[pub_squadron_builder]: https://pub.dev/packages/squadron_builder
