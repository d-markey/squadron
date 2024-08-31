@ECHO OFF

PUSHD "%~dp0..\test"

CALL dart pub global run dhttpd "--headers=Cross-Origin-Embedder-Policy=credentialless;Cross-Origin-Opener-Policy=same-origin"

POPD
