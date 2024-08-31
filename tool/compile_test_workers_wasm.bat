@ECHO OFF
ECHO.Compiling test workers to Web Assembly... 

PUSHD "%~dp0..\test"

CALL dart compile wasm -o .\workers\wasm\cache_worker.dart.wasm        .\workers\js\cache_worker.dart
CALL dart compile wasm -o .\workers\wasm\echo_worker.dart.wasm         .\workers\wasm\echo_worker.dart
CALL dart compile wasm -o .\workers\wasm\installable_worker.dart.wasm  .\workers\js\installable_worker.dart
CALL dart compile wasm -o .\workers\wasm\issues_worker.dart.wasm       .\workers\js\issues_worker.dart
CALL dart compile wasm -o .\workers\wasm\local_client_worker.dart.wasm .\workers\js\local_client_worker.dart
CALL dart compile wasm -o .\workers\wasm\prime_worker.dart.wasm        .\workers\js\prime_worker.dart
CALL dart compile wasm -o .\workers\wasm\not_a_worker.dart.wasm        .\workers\js\not_a_worker.dart
CALL dart compile wasm -o .\workers\wasm\test_worker.dart.wasm         .\workers\js\test_worker.dart

POPD
