@ECHO OFF
PUSHD "%~dp0"

CALL dart run clean_tests.dart %*

POPD
