@ECHO OFF
PUSHD "%~dp0"

CALL dart run squadron_build_hook:standalone_build
REM CALL dart run compile_tests.dart %*

POPD
