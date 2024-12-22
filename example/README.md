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

## Samples

This folder contains examples and tests for Squadron:

* `**hello_world**`: a simple example to execute a service in a pool of workers.
* `**streaming**`: a simple example to execute a service streaming values from a worker.
* `**test**`: various test benchmarks.

However examples here only rely on Squadron and are implemented manually.

This approach is discouraged and it is highly recommended to use squadron_builder in order to generate the boilerplate code in order to have your service run in Squadron workers.
