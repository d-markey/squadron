@ECHO OFF
ECHO.Compiling test workers to JavaScript... 

PUSHD "%~dp0..\test"

SET __OPTIM__=-O4
SET __NO_OPTIM__=-O0

CALL dart compile js %__OPTIM__%    -o .\workers\js\cache_worker.dart.js        .\workers\js\cache_worker.dart
CALL dart compile js %__OPTIM__%    -o .\workers\js\echo_worker.dart.js         .\workers\js\echo_worker.dart
CALL dart compile js %__OPTIM__%    -o .\workers\js\installable_worker.dart.js  .\workers\js\installable_worker.dart
CALL dart compile js %__OPTIM__%    -o .\workers\js\issues_worker.dart.js       .\workers\js\issues_worker.dart
CALL dart compile js %__OPTIM__%    -o .\workers\js\local_client_worker.dart.js .\workers\js\local_client_worker.dart
CALL dart compile js %__OPTIM__%    -o .\workers\js\prime_worker.dart.js        .\workers\js\prime_worker.dart
CALL dart compile js %__OPTIM__%    -o .\workers\js\not_a_worker.dart.js        .\workers\js\not_a_worker.dart
REM do not minify these because some tests inspect the stacktrace for specific names
CALL dart compile js %__NO_OPTIM__% -o .\workers\js\test_worker.dart.js         .\workers\js\test_worker.dart

POPD
