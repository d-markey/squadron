#!/bin/bash
declare -i compile_status=0

pushd "$(dirname $0)/"

dart run compile_tests.dart
compile_status=$?

popd

exit $compile_status
