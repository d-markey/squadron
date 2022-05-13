@echo off
CALL dart compile js -o "%~dp0browser-tests\main.dart.js"   "%~dp0browser-tests\main.dart"
