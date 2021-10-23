CALL dart.bat compile js "%~dp0browser-tests\main.dart" -o "%~dp0browser-tests\main.dart.js"
DEL "%~dp0browser-tests\*.dart.js.deps"
DEL "%~dp0browser-tests\*.dart.js.map"
