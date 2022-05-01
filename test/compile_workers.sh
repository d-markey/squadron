#!/bin/bash
declare -i compile_status=0

workers_minified=("cache_worker" "echo_worker" "issues_worker" "local_client_worker" "prime_worker")
for w in ${workers_minified[@]}
do
    dart compile js -m -o "./test/sample_js_workers/${w}.dart.js" "./test/sample_js_workers/${w}.dart"
    if [ "$compile_status" -eq 0 ]
    then
        compile_status=$?
    fi
done

workers_unminified=("test_worker" "test_worker_failing" "test_worker_invalid")
for w in ${workers_unminified[@]}
do
    dart compile js -o "./test/sample_js_workers/${w}.dart.js" "./test/sample_js_workers/${w}.dart"
    if [ "$compile_status" -eq 0 ]
    then
        compile_status=$?
    fi
done

exit $compile_status
