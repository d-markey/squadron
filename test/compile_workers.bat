@echo off
CALL dart compile js -O4 -o "%~dp0sample_js_workers\cache_worker.dart.js"            "%~dp0sample_js_workers\cache_worker.dart"
CALL dart compile js -O4 -o "%~dp0sample_js_workers\echo_worker.dart.js"             "%~dp0sample_js_workers\echo_worker.dart"
CALL dart compile js -O4 -o "%~dp0sample_js_workers\issues_worker.dart.js"           "%~dp0sample_js_workers\issues_worker.dart"
CALL dart compile js -O4 -o "%~dp0sample_js_workers\local_client_worker.dart.js"     "%~dp0sample_js_workers\local_client_worker.dart"
CALL dart compile js -O4 -o "%~dp0sample_js_workers\prime_worker.dart.js"            "%~dp0sample_js_workers\prime_worker.dart"
rem do not minify these because some tests inspect the stacktrace for specific names
CALL dart compile js     -o "%~dp0sample_js_workers\test_worker_failing.dart.js"     "%~dp0sample_js_workers\test_worker_failing.dart"
CALL dart compile js     -o "%~dp0sample_js_workers\test_worker_invalid.dart.js"     "%~dp0sample_js_workers\test_worker_invalid.dart"
CALL dart compile js     -o "%~dp0sample_js_workers\test_worker.dart.js"             "%~dp0sample_js_workers\test_worker.dart"
