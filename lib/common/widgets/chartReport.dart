// ignore_for_file: must_be_immutable

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:test/common/config/app_color.dart';
import 'package:test/common/config/app_font.dart';
import 'package:test/common/util/tools.dart';

class AllDataCharts {
  AllDataCharts({required this.name, required this.color, this.percent});
  String name;
  Color color;
  double? percent;
}

class ChartsReport extends StatelessWidget {
  ChartsReport({super.key, required this.data});

  List<AllDataCharts> data;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: SfCartesianChart(
                enableAxisAnimation: true,
                palette: [AppColors.mainColor],
                backgroundColor: AppColors.white,
                primaryXAxis: CategoryAxis(
                    labelStyle: AppFont.Title_H6_Bold(color: AppColors.borderColor),
                    rangePadding: ChartRangePadding.auto,
                    labelRotation: 0),
                series: <ChartSeries<AllDataCharts, String>>[
                  // Renders column chart
                  ColumnSeries<AllDataCharts, String>(
                      animationDuration: 1000,
                      dataSource: data,
                      dataLabelSettings: DataLabelSettings(
                        textStyle: AppFont.Body_Regular(size: 13),
                        isVisible: true,
                        showZeroValue: false,
                        color: AppColors.bgLight,
                        // useSeriesColor: true,
                        // Positioning the data label
                      ),
                      emptyPointSettings: EmptyPointSettings(
                          // Mode of empty point
                          mode: EmptyPointMode.average),
                      dataLabelMapper: (AllDataCharts data, _) =>
                          "${Tools.doubleToVND(data.percent ?? 0)}đ",
                      xValueMapper: (AllDataCharts data, _) => data.name,
                      yValueMapper: (AllDataCharts data, _) => data.percent,
                      sortingOrder: SortingOrder.descending,
                      // Sorting based on the specified field
                      sortFieldValueMapper: (AllDataCharts data, _) =>
                          data.percent),
                ])));
  }
}

class CircularCharts extends StatelessWidget {
  CircularCharts({super.key, required this.data});
  List<AllDataCharts> data;

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
        legend: Legend(
            textStyle: AppFont.Title_H6_Bold(),
            isVisible: true,
            overflowMode: LegendItemOverflowMode.wrap,
            position: LegendPosition.bottom),
        series: <CircularSeries>[
          // Renders doughnut chart
          DoughnutSeries<AllDataCharts, String>(
              dataSource: data,
              xValueMapper: (AllDataCharts data, _) => data.name,
              yValueMapper: (AllDataCharts data, _) => data.percent,
              pointColorMapper: (AllDataCharts data, _) => data.color,
              dataLabelMapper: (AllDataCharts data, _) => "${data.percent}%",
              innerRadius: '70%',
              // radius: '100%',
              dataLabelSettings: const DataLabelSettings(
                  textStyle:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  // Renders the data label
                  isVisible: true,
                  useSeriesColor: true,
                  labelPosition: ChartDataLabelPosition.outside)),
        ]);
  }
}
