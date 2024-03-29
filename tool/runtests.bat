@ECHO OFF
SET __ARGS__=
set __REBUILD__=0
SET __COV__=1

PUSHD "%~dp0.."

:parse
IF "%~1"=="" GOTO endparse
IF "%~1"=="/nocov" (
    set __COV__=0
) ELSE IF "%~1"=="--nocov" (
    set __COV__=0
) ELSE IF "%~1"=="-nc" (
    set __COV__=0
) ELSE IF "%~1"=="/nc" (
    set __COV__=0
) ELSE (
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
)
SHIFT
GOTO parse
:endparse

IF "%__REBUILD__%" == "1" (
    CALL .\tool\compile_test_workers.bat
)

rmdir .\test\coverage /s /q
mkdir .\test\coverage
CALL dart run test -j 1 --coverage=.\test\coverage %__ARGS__%
IF "%__COV__%" == "1" (
    CALL dart run coverage:format_coverage --packages=.\.dart_tool\package_config.json --report-on=lib --lcov -o .\test\coverage\lcov.info -i .\test\coverage
    rmdir .\coverage /s /q
    java -jar .\tool\jgenhtml\jgenhtml-1.5.jar .\test\coverage\lcov.info --output-directory .\coverage
    CALL dart run .\tool\xtractcov\main.dart
)

POPD
