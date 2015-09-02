#!/usr/bin/env bash

# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# The directory containing the Angular bundle
ANGULAR=$1

function killServer {
    kill ${serverPid}
}

pushd ${ANGULAR}

node_modules/.bin/gulp serve.js.prod serve.js.dart2js &
serverPid=$!

trap killServer EXIT

# wait for server to come up
sleep 10

node_modules/.bin/protractor protractor-js.conf.js --benchmark --spec="tree_perf.js,largetable_perf.js,naive_infinite_scroll_perf.js"
node_modules/.bin/protractor protractor-dart2js.conf.js --benchmark --spec="tree_perf.js,largetable_perf.js,naive_infinite_scroll_perf.js"
popd
