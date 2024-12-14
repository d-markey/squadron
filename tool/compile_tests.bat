@ECHO OFF
PUSHD "%~dp0"

CALL dart run compile_tests.dart %*

POPD
