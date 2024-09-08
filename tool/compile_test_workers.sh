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

compile "js"   "-O4" "./test/workers/js/cache_worker.dart"         "./test/workers/js/cache_worker.dart.js"
compile "js"   "-O4" "./test/workers/js/echo_worker.dart"          "./test/workers/js/echo_worker.dart.js"
compile "js"   "-O4" "./test/workers/js/installable_worker.dart"   "./test/workers/js/installable_worker.dart.js"
compile "js"   "-O4" "./test/workers/js/issues_worker.dart"        "./test/workers/js/issues_worker.dart.js"
compile "js"   "-O4" "./test/workers/js/local_client_worker.dart"  "./test/workers/js/local_client_worker.dart.js"
compile "js"   "-O4" "./test/workers/js/prime_worker.dart"         "./test/workers/js/prime_worker.dart.js"
compile "js"   ""    "./test/workers/js/test_worker.dart"          "./test/workers/js/test_worker.dart.js"

compile "wasm" "-O4" "./test/workers/js/cache_worker.dart"         "./test/workers/wasm/cache_worker.dart.wasm"
compile "wasm" "-O4" "./test/workers/wasm/echo_worker.dart"        "./test/workers/wasm/echo_worker.dart.wasm"
compile "wasm" "-O4" "./test/workers/js/installable_worker.dart"   "./test/workers/wasm/installable_worker.dart.wasm"
compile "wasm" "-O4" "./test/workers/js/issues_worker.dart"        "./test/workers/wasm/issues_worker.dart.wasm"
compile "wasm" "-O4" "./test/workers/js/local_client_worker.dart"  "./test/workers/wasm/local_client_worker.dart.wasm"
compile "wasm" "-O4" "./test/workers/js/prime_worker.dart"         "./test/workers/wasm/prime_worker.dart.wasm"
compile "wasm" ""    "./test/workers/js/test_worker.dart"          "./test/workers/wasm/test_worker.dart.wasm"

popd

exit $compile_status
