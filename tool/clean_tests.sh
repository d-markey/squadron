#!/bin/bash
pushd "$(dirname $0)/"

dart run clean_tests.dart

popd
