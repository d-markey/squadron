<!doctype html>
<html>
  <head>
    <title>Squadron Web Worker Tests (wasm) - {{testName}}</title>
    {{testScript}}
    <link rel="x-web-worker" href="workers/wasm/native_worker.js">
    <link rel="x-web-worker" href="workers/wasm/not_a_worker.dart.unopt.wasm">
    <link rel="x-web-worker" href="workers/wasm/echo_worker.dart.unopt.wasm">

    <link rel="x-web-worker" href="workers/wasm/cache_worker.dart.unopt.wasm">
    <link rel="x-web-worker" href="workers/wasm/installable_worker.dart.unopt.wasm">
    <link rel="x-web-worker" href="workers/wasm/issues_worker.dart.unopt.wasm">
    <link rel="x-web-worker" href="workers/wasm/local_client_worker.dart.unopt.wasm">
    <link rel="x-web-worker" href="workers/wasm/prime_worker.dart.unopt.wasm">

    <link rel="x-web-worker" href="workers/wasm/test_worker.dart.unopt.wasm">
    <script src="packages/test/dart.js"></script>
  </head>
</html>
