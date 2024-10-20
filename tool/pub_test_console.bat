@ECHO OFF
SET __REBUILD__=0

PUSHD "%~dp0.."

:parse
IF "%~1"=="" GOTO endparse
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

:nextarg
SHIFT
GOTO parse
:endparse

IF "%__REBUILD__%" == "1" (
    CALL .\tool\compile_all_tests.bat
)

RMDIR /S /Q .\doc\browser-tests
RMDIR /S /Q .\doc\workers

MKDIR .\doc\browser-tests
MKDIR .\doc\workers
MKDIR .\doc\workers\js
MKDIR .\doc\workers\wasm

CALL :DEPLOY browser-tests
CALL :DEPLOY workers\js
CALL :DEPLOY workers\wasm

GOTO EOF

:DEPLOY
COPY .\test\%~1\*.html .\doc\%~1
COPY .\test\%~1\*.css .\doc\%~1
COPY .\test\%~1\*.js .\doc\%~1
COPY .\test\%~1\*.mjs .\doc\%~1
COPY .\test\%~1\*.wasm .\doc\%~1
COPY .\test\%~1\*.map .\doc\%~1
COPY .\test\%~1\*.deps .\doc\%~1

EXIT /B 0

:EOF