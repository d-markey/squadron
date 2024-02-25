@echo off
PUSHD "%~dp0..\test"

CALL dart compile js -o .\browser-tests\main.dart.js .\browser-tests\main.dart

POPD
