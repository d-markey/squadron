@ECHO OFF

PUSHD "%~dp0.."

CALL dart run .\tool\set_version.dart
CALL dart format .
CALL .\tool\pub_test_console.bat --rebuild
