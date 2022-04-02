@echo off
rem do not minify compiled JavaScript for RogueWorker because some tests inspect the stacktrace for specific names
CALL dart.bat compile js -m -o "%~dp0sample_js_workers\bitcoin_worker.dart.js"         "%~dp0sample_js_workers\bitcoin_worker.dart"
CALL dart.bat compile js -m -o "%~dp0sample_js_workers\cache_worker.dart.js"           "%~dp0sample_js_workers\cache_worker.dart"
CALL dart.bat compile js -m -o "%~dp0sample_js_workers\echo_worker.dart.js"            "%~dp0sample_js_workers\echo_worker.dart"
CALL dart.bat compile js -m -o "%~dp0sample_js_workers\failing_worker.dart.js"         "%~dp0sample_js_workers\failing_worker.dart"
CALL dart.bat compile js -m -o "%~dp0sample_js_workers\invalid_worker.dart.js"         "%~dp0sample_js_workers\invalid_worker.dart"
CALL dart.bat compile js -m -o "%~dp0sample_js_workers\local_client_worker.dart.js"    "%~dp0sample_js_workers\local_client_worker.dart"
CALL dart.bat compile js -m -o "%~dp0sample_js_workers\pi_digits_worker.dart.js"       "%~dp0sample_js_workers\pi_digits_worker.dart"
CALL dart.bat compile js -m -o "%~dp0sample_js_workers\prime_worker.dart.js"           "%~dp0sample_js_workers\prime_worker.dart"
CALL dart.bat compile js    -o "%~dp0sample_js_workers\rogue_worker.dart.js"           "%~dp0sample_js_workers\rogue_worker.dart"
CALL dart.bat compile js -m -o "%~dp0sample_js_workers\sample_worker.dart.js"          "%~dp0sample_js_workers\sample_worker.dart"
DEL "%~dp0sample_js_workers\*.dart.js.deps"
DEL "%~dp0sample_js_workers\*.dart.js.map"
