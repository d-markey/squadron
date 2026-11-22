#!/bin/bash
declare -i compile_status=0

pushd "$(dirname $0)/"

#dart run compile_tests.dart
dart run squadron_build_hook:standalone_build
compile_status=$?

popd

exit $compile_status
