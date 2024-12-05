@ECHO OFF
PUSHD "%~dp0"

CALL compile_test_workers_js.bat
CALL compile_test_workers_wasm.bat

POPD
