@echo off
PUSHD "%~dp0..\test"

CALL dart compile js -o .\browser-tests\index.dart.js .\browser-tests\index.dart
CALL dart compile js -o .\browser-tests\test_runner.dart.js .\browser-tests\test_runner.dart

POPD
