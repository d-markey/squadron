rmdir .\test\coverage /s /q
mkdir .\test\coverage
call .\test\compile_workers.bat
call dart run test --coverage=.\test\coverage %*
call dart pub global run coverage:format_coverage --packages=.packages --report-on=lib --lcov -o .\test\coverage\lcov.info -i .\test\coverage
rmdir .\coverage /s /q
java -jar .\tool\jgenhtml\jgenhtml-1.5.jar .\test\coverage\lcov.info --output-directory .\coverage  
