@ECHO OFF
ECHO.Compiling custom browser test console to JavaScript and Web Assembly... 

PUSHD "%~dp0..\test"

CALL dart compile js -o .\browser-tests\index.dart.js .\browser-tests\index.dart

CALL dart compile js -o .\browser-tests\test_runner_js2js.dart.js .\browser-tests\test_runner_js2js.dart
CALL dart compile js -o .\browser-tests\test_runner_js2wasm.dart.js .\browser-tests\test_runner_js2wasm.dart

CALL dart compile wasm -o .\browser-tests\test_runner_wasm2js.dart.wasm .\browser-tests\test_runner_wasm2js.dart
CALL dart compile wasm -o .\browser-tests\test_runner_wasm2wasm.dart.wasm .\browser-tests\test_runner_wasm2wasm.dart

POPD
