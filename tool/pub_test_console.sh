#!/bin/bash

pushd $(dirname $0)/..

publish() { # arguments: folder
    cp ./test/$1/*.html ./doc/$1
    cp ./test/$1/*.css ./doc/$1
    cp ./test/$1/*.js ./doc/$1
    cp ./test/$1/*.mjs ./doc/$1
    cp ./test/$1/*.wasm ./doc/$1
    cp ./test/$1/*.map ./doc/$1
    cp ./test/$1/*.deps ./doc/$1
}

dart compile js   -O4 -o ./test/browser-tests/index.dart.js                   ./test/browser-tests/index.dart
dart compile js   -O4 -o ./test/browser-tests/test_runner_js2js.dart.js       ./test/browser-tests/test_runner_js2js.dart
dart compile js   -O4 -o ./test/browser-tests/test_runner_js2wasm.dart.js     ./test/browser-tests/test_runner_js2wasm.dart
dart compile wasm -O4 -o ./test/browser-tests/test_runner_wasm2js.dart.wasm   ./test/browser-tests/test_runner_wasm2js.dart
dart compile wasm -O4 -o ./test/browser-tests/test_runner_wasm2wasm.dart.wasm ./test/browser-tests/test_runner_wasm2wasm.dart

publish browser_tests
publish workers/js
publish workers/wasm

git stash
git checkout gh-pages
git stash apply

git config --global user.name 'd-markey'
git config --global user.email 'd-markey@users.noreply.github.com'
git commit -am Test console
git push

popd
