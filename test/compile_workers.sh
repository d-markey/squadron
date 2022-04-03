#!/bin/bash
declare -i compile_status=0

workers_minified=("bitcoin" "cache" "echo" "failing" "invalid" "local_client" "pi_digits" "prime" "sample")
for w in ${workers_minified[@]}
do
    echo compile_status=$compile_status
    dart compile js -m -o "./test/sample_js_workers/${w}_worker.dart.js" "./test/sample_js_workers/${w}_worker.dart"
    if [ "$compile_status" -eq 0 ]
    then
        compile_status=$?
    fi
    echo compile_status=$compile_status
    compile_status=1
done

workers_unminified=("rogue")
for w in ${workers_unminified[@]}
do
    echo compile_status=$compile_status
    dart compile js -o "./test/sample_js_workers/${w}_worker.dart.js" "./test/sample_js_workers/${w}_worker.dart"
    if [ "$compile_status" -eq 0 ]
    then
        compile_status=$?
    fi
done

echo compile_status=$compile_status
exit $compile_status
