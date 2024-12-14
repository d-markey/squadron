#!/bin/bash

pushd "$(dirname $0)/.."

publish() { # arguments: folder
    cp ./test/$1/*.html ./doc/$1
    cp ./test/$1/*.css ./doc/$1
    cp ./test/$1/*.js ./doc/$1
    cp ./test/$1/*.mjs ./doc/$1
    cp ./test/$1/*.wasm ./doc/$1
    cp ./test/$1/*.map ./doc/$1
    cp ./test/$1/*.deps ./doc/$1
}

dart run ./tool/clean_tests.dart
dart run ./tool/compile_tests.dart

git checkout gh-pages

publish browser_tests
publish workers/js
publish workers/wasm

git config --global user.name 'd-markey'
git config --global user.email 'd-markey@users.noreply.github.com'
git commit -am "Test console"
git push

popd
