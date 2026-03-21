#!/bin/bash

# initialize variables
__ARGS__=()
__REBUILD__=0
__COV__=0

# parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    /cov|--cov|-c|/c)
      __COV__=1
      shift
      ;;
    /rebuild|--rebuild|-b|/b)
      __REBUILD__=1
      shift
      ;;
    *)
      __ARGS__+=("$1")
      shift
      ;;
  esac
done

pushd "$(dirname "$0")/.." > /dev/null

# rebuild workers if requested
if [[ "$__REBUILD__" == "1" ]]; then
  dart run ./tool/compile_tests.dart js wasm
fi

# run tests
if [[ "$__COV__" == "1" ]]; then
  rm -rf ./test/coverage
  mkdir -p ./test/coverage
  dart test -j 1 --coverage=./test/coverage "${__ARGS__[@]}"
  test_status=$?
  
  if [[ $test_status -eq 0 ]]; then
    dart run coverage:format_coverage --packages=./.dart_tool/package_config.json --report-on=lib --lcov -o ./test/coverage/lcov.info -i ./test/coverage
    rm -rf ./doc/coverage
    java -jar ./tool/jgenhtml/jgenhtml-1.6.jar ./test/coverage/lcov.info --output-directory ./doc/coverage
    dart run ./tool/xtractcov/main.dart
  fi
else
  dart test -j 1 "${__ARGS__[@]}"
  test_status=$?
fi

popd > /dev/null

exit $test_status
