@echo off

PUSHD "%~dp0..\test"

set __OPTIM__=-O4

CALL dart compile js %__OPTIM__% -o .\sample_js_workers\cache_worker.dart.js        .\sample_js_workers\cache_worker.dart
CALL dart compile js %__OPTIM__% -o .\sample_js_workers\echo_worker.dart.js         .\sample_js_workers\echo_worker.dart
CALL dart compile js %__OPTIM__% -o .\sample_js_workers\installable_worker.dart.js  .\sample_js_workers\installable_worker.dart
CALL dart compile js %__OPTIM__% -o .\sample_js_workers\issues_worker.dart.js       .\sample_js_workers\issues_worker.dart
CALL dart compile js %__OPTIM__% -o .\sample_js_workers\local_client_worker.dart.js .\sample_js_workers\local_client_worker.dart
CALL dart compile js %__OPTIM__% -o .\sample_js_workers\prime_worker.dart.js        .\sample_js_workers\prime_worker.dart
rem do not minify these because some tests inspect the stacktrace for specific names
CALL dart compile js             -o .\sample_js_workers\test_worker.dart.js         .\sample_js_workers\test_worker.dart

CALL dart compile wasm -o .\sample_wasm_workers\cache_worker.dart.wasm        .\sample_js_workers\cache_worker.dart
CALL dart compile wasm -o .\sample_wasm_workers\echo_worker.dart.wasm         .\sample_js_workers\echo_worker.dart
CALL dart compile wasm -o .\sample_wasm_workers\installable_worker.dart.wasm  .\sample_js_workers\installable_worker.dart
CALL dart compile wasm -o .\sample_wasm_workers\issues_worker.dart.wasm       .\sample_js_workers\issues_worker.dart
CALL dart compile wasm -o .\sample_wasm_workers\local_client_worker.dart.wasm .\sample_js_workers\local_client_worker.dart
CALL dart compile wasm -o .\sample_wasm_workers\prime_worker.dart.wasm        .\sample_js_workers\prime_worker.dart
rem do not minify these because some tests inspect the stacktrace for specific names
CALL dart compile wasm -o .\sample_wasm_workers\test_worker.dart.wasm         .\sample_js_workers\test_worker.dart

POPD
