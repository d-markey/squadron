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

## <a name="getting_started"></a>Getting Started

1. Update your `pubspec.yaml` file to add dependencies to `squadron` and `squadron_builder`:

```yaml
dependencies:
  squadron: ^6.0.0
  # ...
  # other dependencies used by your app
  # ...

dev_dependencies:
  build_runner:
  squadron_builder: ^6.0.0
  # ...
  # other dev dependencies used by your app
  # ...
```

2. Have dart download and install the dependencies:

```
dart pub get
```

## <a name="implement"></a>Implementing a Service

Create a class containing the code you want to run in a dedicated thread and make sure you provide `squadron` annotations:
* use `SquadronService` for the class;
* use `SquadronMethod` for the methods you want to expose.

Service methods must return a `Future<T>`, a `FutureOr<T>` or a `Stream<T>`.

```dart
// file hello_world.dart
import 'dart:async';

import 'package:squadron/squadron.dart';

import 'hello_world.activator.g.dart';
part 'hello_world.worker.g.dart';

@SquadronService(baseUrl: '~/workers', targetPlatform: TargetPlatform.vm | TargetPlatform.web)
base class HelloWorld {
  @SquadronMethod()
  FutureOr<String> hello([String? name]) {
    name = name?.trim() ?? 'World';
    return 'Hello, $name!';
  }
}
```

## <a name="build"></a>Generate the Worker and WorkerPool code

Have `squadron_builder` generate the code with the following command line:

```
dart run build_runner build
```

This command will create the worker and worker pool from your service: `HelloWorldWorker` and `HelloWorldWorkerPool`.

## <a name="run"></a>Run your code

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

If your app runs in a browser, you must compile your code to JavaScript or Wasm.

```
dart compile js .\hello_world.web.g.dart -o ..\web\workers\hello_world.web.g.dart.js
dart compile wasm .\hello_world.web.g.dart -o ..\web\workers\hello_world.web.g.dart.wasm
```

## <a name="thanks"></a>Thanks!

* [Saad Ardati](https://github.com/SaadArdati) for his patience and feedback when implementing Squadron into his Flutter application.
* [Martin Fink](https://github.com/martin-robert-fink) for the feedback on Squadron's `Stream` implementation -- this has resulted in huge progress and a major improvement!
* [Klemen Tusar](https://github.com/techouse) for providing a [sample Chopper JSON decoder](https://hadrien-lejard.gitbook.io/chopper/faq#decoding-json-using-isolates) leveraging Squadron.



[pub_squadron_builder]: https://pub.dev/packages/squadron_builder
[pub_json_annotation]: https://pub.dev/packages/json_annotation
[pub_json_serializable]: https://pub.dev/packages/json_serializable
[pub_logging]: https://pub.dev/packages/logging