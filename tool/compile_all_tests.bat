@ECHO OFF
PUSHD "%~dp0"

CALL compile_browser_tests.bat
CALL compile_test_workers.bat

POPD
