@ECHO OFF

IF "%1" == "fromdoc" (
    PUSHD "%~dp0..\doc"
) ELSE (
    PUSHD "%~dp0..\test"
)



@REM CALL dart pub global run dhttpd "--headers=Cross-Origin-Embedder-Policy=credentialless;Cross-Origin-Opener-Policy=same-origin"
CALL dart pub global run dhttpd --port=7777

POPD
