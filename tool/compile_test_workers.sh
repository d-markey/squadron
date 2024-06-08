#!/bin/bash
declare -i compile_status=0

pushd "$(dirname $0)/.."

compile() { # arguments: platform, optim, source, target
    if (( $compile_status == 0 ))
    then
        dart compile $1 $2  $3 -o $4
        compile_status=$?
        if (( $compile_status != 0 ))
        then
            echo "Compilation failed for $1 $2  $3 -o $4"
        fi
    fi
}

compile "js"   "-O4" "./test/sample_js_workers/cache_worker.dart"         "./test/sample_js_workers/cache_worker.dart.js"
compile "js"   "-O4" "./test/sample_js_workers/echo_worker.dart"          "./test/sample_js_workers/echo_worker.dart.js"
compile "js"   "-O4" "./test/sample_js_workers/installable_worker.dart"   "./test/sample_js_workers/installable_worker.dart.js"
compile "js"   "-O4" "./test/sample_js_workers/issues_worker.dart"        "./test/sample_js_workers/issues_worker.dart.js"
compile "js"   "-O4" "./test/sample_js_workers/local_client_worker.dart"  "./test/sample_js_workers/local_client_worker.dart.js"
compile "js"   "-O4" "./test/sample_js_workers/prime_worker.dart"         "./test/sample_js_workers/prime_worker.dart.js"
compile "js"   ""    "./test/sample_js_workers/test_worker.dart"          "./test/sample_js_workers/test_worker.dart.js"

compile "wasm" ""    "./test/sample_js_workers/cache_worker.dart"         "./test/sample_wasm_workers/cache_worker.dart.wasm"
compile "wasm" ""    "./test/sample_wasm_workers/echo_worker.dart"        "./test/sample_wasm_workers/echo_worker.dart.wasm"
compile "wasm" ""    "./test/sample_js_workers/installable_worker.dart"   "./test/sample_wasm_workers/installable_worker.dart.wasm"
compile "wasm" ""    "./test/sample_js_workers/issues_worker.dart"        "./test/sample_wasm_workers/issues_worker.dart.wasm"
compile "wasm" ""    "./test/sample_js_workers/local_client_worker.dart"  "./test/sample_wasm_workers/local_client_worker.dart.wasm"
compile "wasm" ""    "./test/sample_js_workers/prime_worker.dart"         "./test/sample_wasm_workers/prime_worker.dart.wasm"
compile "wasm" ""    "./test/sample_js_workers/test_worker.dart"          "./test/sample_wasm_workers/test_worker.dart.wasm"

popd

exit $compile_status
