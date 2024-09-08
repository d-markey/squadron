#!/bin/bash
declare -i test_status=0

pushd "$(dirname $0)/.."

# clean coverage directory
rm -rf ./test/coverage
mkdir ./test/coverage

# run tests
dart test -j 1 --coverage=./test/coverage
test_status=$?

# generate coverage report if tests succeed
if (( $test_status == 0 ))
then
    dart run coverage:format_coverage --packages=./.dart_tool/package_config.json --report-on=lib --lcov -o ./test/coverage/lcov.info -i ./test/coverage
    rm -rf ./doc/coverage
    java -jar ./tool/jgenhtml/jgenhtml-1.5.jar ./test/coverage/lcov.info --output-directory ./doc/coverage
    dart run ./tool/xtractcov/main.dart

    git config --global user.name 'd-markey'
    git config --global user.email 'd-markey@users.noreply.github.com'
    git commit -am "Automated test coverage report"
    git push
fi

popd

# return test status
exit $test_status
