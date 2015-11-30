// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:charted/charts/charts.dart';
import 'package:observe/observe.dart';

import 'dart:convert';
import 'dart:html';
import 'dart:math';

Iterable _columns = [
  new ChartColumnSpec(label: 'Benchmark', type: ChartColumnSpec.TYPE_STRING),
  new ChartColumnSpec(label: 'js Runtime (ms)'),
  new ChartColumnSpec(label: 'dart2js (ssa) Runtime (ms)'),
  new ChartColumnSpec(label: 'dart2js (cps) Runtime (ms)')
];

Set<String> treeBenchmarks = new Set.from(
    ['ng2.tree.create.plain', 'ng2.tree.create.viewcache', 'ng2.tree.update']);

Set<String> staticTreeBenchmarks = new Set.from([
  'ng2.static.tree.create.plain',
  'ng2.static.tree.create.viewcache',
  'ng2.static.tree.update'
]);

Set<String> largetableBenchmarks = new Set.from([
  'ng2.largetable.interpolation',
  'ng2.largetable.interpolation.plain',
  'ng2.largetable.interpolationAttr',
  'ng2.largetable.interpolationFn',
]);

Set<String> naiveInfiniteScrollBenchmarks = new Set.from([
  'ng2.naive_infinite_scroll1',
  'ng2.naive_infinite_scroll2',
  'ng2.naive_infinite_scroll4'
]);

Map uploadedJson;
List rawRows;

main() {
  var fileUpload = querySelector('#file_upload');
  fileUpload.onChange.listen((event) {
    var file = (event.target as InputElement).files.first;
    var reader = new FileReader();
    reader.onLoad.first.then((_) {
      var contents = reader.result;
      uploadedJson = JSON.decode(contents);
      querySelector('#upload_results').hidden = true;
      rawRows = parseToRows(uploadedJson);
      showCharts();
      showMeans();
    });
    reader.readAsText(file);
  });
}

void showCharts() {
  renderChart('#tree_chart', treeBenchmarks);
  renderChart('#static_tree_chart', staticTreeBenchmarks);
  renderChart('#largetable_chart', largetableBenchmarks);
  renderChart('#naive_infinite_scroll_chart', naiveInfiniteScrollBenchmarks);
}

void showMeans() {
  var treeMean = showMean('tree', treeBenchmarks);
  var staticTreeMean = showMean('static_tree', staticTreeBenchmarks);
  var largeTableMean = showMean('largetable', largetableBenchmarks);
  var naiveInfiniteScrollMean =
      showMean('naive_infinite_scroll', naiveInfiniteScrollBenchmarks);
  var totalMean = showMean(
      'ssa vs js',
      treeBenchmarks
          .union(largetableBenchmarks)
          .union(naiveInfiniteScrollBenchmarks)
          .union(staticTreeBenchmarks));
  var cpsJsMean = showMean(
      'cps vs js',
      treeBenchmarks
          .union(largetableBenchmarks)
          .union(naiveInfiniteScrollBenchmarks)
          .union(staticTreeBenchmarks),
      denom: 3);
  var cpsSsaMean = showMean(
      'cps vs ssa',
      treeBenchmarks
          .union(largetableBenchmarks)
          .union(naiveInfiniteScrollBenchmarks)
          .union(staticTreeBenchmarks), denom: 3, numer: 2);

  var meansDiv = querySelector('#means');
  meansDiv.append(new UListElement()
    ..append(new LIElement()..text = treeMean)
    ..append(new LIElement()..text = staticTreeMean)
    ..append(new LIElement()..text = largeTableMean)
    ..append(new LIElement()..text = naiveInfiniteScrollMean)
    ..append(new LIElement()..text = totalMean)
    ..append(new LIElement()..text = cpsJsMean)
    ..append(new LIElement()..text = cpsSsaMean));
}

// XXX: rename denom and numer
String showMean(String name, Set<String> benchmarks, {int denom: 2, int numer: 1}) {
  var mean = geoMean(
      rawRows.where((x) => benchmarks.contains(x[0])).map((x) => x[denom] / x[numer]));
  return 'Average performance on $name benchmarks: $mean';
}

double geoMean(Iterable<double> values) {
  double product = 1.0;
  int len = 0;
  for (var value in values) {
    product *= value;
    len++;
  }
  return pow(product, 1 / len);
}

void renderChart(String id, Set<String> benchmarks) {
  var chart = querySelector(id);
  var rows =
      new ObservableList.from(rawRows.where((x) => benchmarks.contains(x[0])));
  var columns = new ObservableList.from(_columns);
  var data = new ChartData(columns, rows);
  var seriesList = new ObservableList.from([
    new ChartSeries('Default', new ObservableList.from([1, 2, 3]),
        new BarChartRenderer(alwaysAnimate: true))
  ]);
  var config = new ChartConfig(seriesList, [0]);
  var area = new CartesianArea(chart, data, config,
      autoUpdate: true, useTwoDimensionAxes: false);
  area.addChartBehavior(new Hovercard());
  area.draw();
}

List parseToRows(Map json) {
  var jsScores = {};
  var ssaScores = {};
  var cpsScores = {};
  for (var result in json['js']) {
    jsScores[result['benchmark']] = result['score'];
  }
  for (var result in json['ssa']) {
    ssaScores[result['benchmark']] = result['score'];
  }
  for (var result in json['cps']) {
    cpsScores[result['benchmark']] = result['score'];
  }
  var rows = [];
  for (var benchmark in jsScores.keys) {
    rows.add([benchmark, jsScores[benchmark], ssaScores[benchmark], cpsScores[benchmark]]);
  }
  return rows;
}
