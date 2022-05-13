#!/bin/bash
declare -i test_status=0

# clean coverage directory
rm -rf ./test/coverage
mkdir ./test/coverage

# run tests
dart test --coverage=./test/coverage
test_status=$?

# generate coverage report if tests succeed
if [ "$test_status" -eq 0 ]
then
    dart run coverage:format_coverage --packages=./.dart_tool/package_config.json --report-on=lib --lcov -o ./test/coverage/lcov.info -i ./test/coverage
    rm -rf ./coverage
    java -jar ./tool/jgenhtml/jgenhtml-1.5.jar ./test/coverage/lcov.info --output-directory ./coverage
    dart run ./tool/xtractcov/main.dart

    git config --global user.name 'd-markey'
    git config --global user.email 'd-markey@users.noreply.github.com'
    git add ./coverage
    git add ./coverage.json
    git commit -am "Automated test coverage report"
    git push
fi

# return test status
exit $test_status
