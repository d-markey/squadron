@echo off
CALL dart.bat compile js -o "%~dp0browser-tests\main.dart.js"   "%~dp0browser-tests\main.dart"
DEL "%~dp0browser-tests\*.dart.js.deps"
DEL "%~dp0browser-tests\*.dart.js.map"
