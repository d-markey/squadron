#!/bin/bash
echo Cleaning ./test/coverage directory...
rm -rf ./test/coverage
mkdir ./test/coverage

echo Running tests
dart test --coverage=./test/coverage
test_status=$?
echo test status = $test_status

echo Contents of ./test/coverage
ls -R ./test/coverage

echo Generate lcov.info file
dart pub run coverage:format_coverage --packages=.packages --report-on=lib --lcov -o ./test/coverage/lcov.info -i ./test/coverage

echo Generate coverage reports...
rm -rf ./coverage /s /q
java -jar ./tool/jgenhtml/jgenhtml-1.5.jar ./test/coverage/lcov.info --output-directory ./coverage  

echo Returning with exit code = $test_status
exit $test_status
