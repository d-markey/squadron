#!/bin/bash
rm -rf ./test/coverage
mkdir ./test/coverage
dart run test --coverage=./test/coverage
ls -R ./test/coverage
dart pub global run coverage:format_coverage --packages=.packages --report-on=lib --lcov -o ./test/coverage/lcov.info -i ./test/coverage
rm -rf ./coverage /s /q
java -jar ./tool/jgenhtml/jgenhtml-1.5.jar ./test/coverage/lcov.info --output-directory ./coverage  
