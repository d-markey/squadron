@echo off
PUSHD "%~dp0..\test"

CALL dart compile js -o .\browser-tests\index.dart.js .\browser-tests\index.dart
CALL dart compile js -o .\browser-tests\test_runner_js.dart.js .\browser-tests\test_runner_js.dart
CALL dart compile js -o .\browser-tests\test_runner_wasm.dart.js .\browser-tests\test_runner_wasm.dart

CALL dart compile wasm -o .\browser-tests\wasm_test_runner_wasm.dart.wasm .\browser-tests\test_runner_wasm.dart

REM CALL dart compile js -o .\browser-wasm-tests\index.dart.js .\browser-wasm-tests\index.dart
REM CALL dart compile js -o .\browser-wasm-tests\test_runner.dart.js .\browser-wasm-tests\test_runner.dart

POPD
