@ECHO OFF
SET __ARGS__=
SET __REBUILD__=0
SET __COV__=0

PUSHD "%~dp0.."

:parse
IF "%~1"=="" GOTO endparse
REM code coverage flag
IF "%~1"=="/cov" (
    SET __COV__=1
    GOTO nextarg
) ELSE IF "%~1"=="--cov" (
    SET __COV__=1
    GOTO nextarg
) ELSE IF "%~1"=="-c" (
    SET __COV__=1
    GOTO nextarg
) ELSE IF "%~1"=="/c" (
    SET __COV__=1
    GOTO nextarg
) 
REM rebuild flag
IF "%~1"=="/rebuild" (
    SET __REBUILD__=1
    GOTO nextarg
) ELSE IF "%~1"=="--rebuild" (
    SET __REBUILD__=1
    GOTO nextarg
) ELSE IF "%~1"=="-b" (
    SET __REBUILD__=1
    GOTO nextarg
) ELSE IF "%~1"=="/b" (
    SET __REBUILD__=1
    GOTO nextarg
)
REM arg for dart test
SET __ARGS__=%__ARGS__% "%~1"

:nextarg
SHIFT
GOTO parse
:endparse

IF "%__REBUILD__%" == "1" (
    CALL .\tool\compile_test_workers_js.bat
    CALL .\tool\compile_test_workers_wasm.bat
)

RMDIR .\test\coverage /s /q
MKDIR .\test\coverage
CALL dart test -j 1 --coverage=.\test\coverage %__ARGS__%
IF "%__COV__%" == "1" (
    CALL dart run coverage:format_coverage --packages=.\.dart_tool\package_config.json --report-on=lib --lcov -o .\test\coverage\lcov.info -i .\test\coverage
    RMDIR .\doc\coverage /s /q
    java -jar .\tool\jgenhtml\jgenhtml-1.6.jar .\test\coverage\lcov.info --output-directory .\doc\coverage
    CALL dart run .\tool\xtractcov\main.dart
)

POPD
