// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Create a results.json file from a manual run of angular2 benchmarks.
///     1. `xvfb-run lib/src/data/run_benchmarks.sh /path/to/angular`
///     2. `dart bin/create_results.dart /path/to/angular`
library angularchart.create_results;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

main(List<String> args) async {
  var resultsDir = new Directory(path.join(args[0], 'dist/benchmark_results'));
  var scores = {'js': [], 'dart2js': []};
  resultsDir.list().listen((file) {
    var contents = file.readAsStringSync();
    var results = JSON.decode(contents);
    var benchmark = results['description']['id'];
    if (benchmark == 'ng2.naive_infinite_scroll') {
      benchmark += results['description']['description']['appSize'].toString();
    }
    var target = results['description']['description']['lang'] == 'js'
        ? 'js'
        : 'dart2js';
    var score = getScore(results['validSample']);
    scores[target].add({'benchmark': benchmark, 'score': score});
  }, onDone: () {
    new File('results.json').writeAsString(JSON.encode(scores));
  });
}

double getScore(List samples) {
  var sum = samples.fold(0.0, (a, b) => a + b['values']['pureScriptTime']);
  return (sum / samples.length) * 1000;
}
