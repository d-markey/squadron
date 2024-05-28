@ECHO OFF
SET __ARGS__=
SET __REBUILD__=0
SET __COV__=0

PUSHD "%~dp0.."

:parse
IF "%~1"=="" GOTO endparse
REM code coverage flag
IF "%~1"=="/cov" (
    set __COV__=1
) ELSE IF "%~1"=="--cov" (
    set __COV__=1
) ELSE IF "%~1"=="-c" (
    set __COV__=1
) ELSE IF "%~1"=="/c" (
    set __COV__=1
) 
REM rebuild flag
IF "%~1"=="/rebuild" (
    set __REBUILD__=1
) ELSE IF "%~1"=="--rebuild" (
    set __REBUILD__=1
) ELSE IF "%~1"=="-b" (
    set __REBUILD__=1
) ELSE IF "%~1"=="/b" (
    set __REBUILD__=1
) ELSE (
    set __ARGS__=%__ARGS__% "%~1"
)
SHIFT
GOTO parse
:endparse

IF "%__REBUILD__%" == "1" (
    CALL .\tool\compile_test_workers_js.bat
    CALL .\tool\compile_test_workers_wasm.bat
)

RMDIR .\test\coverage /s /q
MKDIR .\test\coverage
CALL dart run test -j 1 --coverage=.\test\coverage %__ARGS__%
IF "%__COV__%" == "1" (
    CALL dart run coverage:format_coverage --packages=.\.dart_tool\package_config.json --report-on=lib --lcov -o .\test\coverage\lcov.info -i .\test\coverage
    RMDIR .\coverage /s /q
    java -jar .\tool\jgenhtml\jgenhtml-1.5.jar .\test\coverage\lcov.info --output-directory .\coverage
    CALL dart run .\tool\xtractcov\main.dart
)

POPD
