#!/bin/bash
declare -i compile_status=0

workers_minified=("bitcoin" "cache" "echo" "failing" "invalid" "local_client" "pi_digits" "prime" "sample")
for w in ${workers_minified[@]}
do
    dart compile js -m -o "./test/sample_js_workers/${w}_worker.dart.js" "./test/sample_js_workers/${w}_worker.dart"
    if [ "$compile_status" -eq 0 ]
    then
        compile_status=$?
    fi
done

workers_unminified=("rogue")
for w in ${workers_unminified[@]}
do
    dart compile js -o "./test/sample_js_workers/${w}_worker.dart.js" "./test/sample_js_workers/${w}_worker.dart"
    if [ "$compile_status" -eq 0 ]
    then
        compile_status=$?
    fi
done

exit $compile_status
