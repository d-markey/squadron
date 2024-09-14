@ECHO OFF

PUSHD "%~dp0..\test"

@REM CALL dart pub global run dhttpd "--headers=Cross-Origin-Embedder-Policy=credentialless;Cross-Origin-Opener-Policy=same-origin"
CALL dart pub global run dhttpd

POPD
