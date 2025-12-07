import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:monitoramentoapp/generals/metrics.dart';
import 'package:monitoramentoapp/generals/globals.dart';

// Ex de uso:
// MetricChart(
//  dataStore: MetricDataManager.getInstance("gpu"),
//  unitSuffix: 'ms',
//  minY: 0,
//  maxY: 200,
//)

class MetricChart extends StatelessWidget {
  final MetricData dataStore;
  final String unitSuffix;
  final double? minY;
  final double? maxY;

  const MetricChart({
    super.key,
    required this.dataStore,
    required this.unitSuffix,
    this.minY,
    this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final dataMap = isRealTime ? dataStore.realData : dataStore.histData;
    final labelMap =
        isRealTime ? dataStore.timeLabelsReal : dataStore.timeLabelsHist;
    final epochMap =
        isRealTime ? dataStore.timeEpochsReal : dataStore.timeEpochsHist;

    return Expanded(
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final allLabels = <String>[];
                  final allXs = <double>[];

                  for (final serviceName in dataMap.keys) {
                    final dataList = dataMap[serviceName];
                    final labels = labelMap[serviceName];
                    final epochs = epochMap[serviceName];

                    if (dataList != null && labels != null && epochs != null) {
                      final len = [
                        dataList.length,
                        labels.length,
                        epochs.length
                      ].reduce((a, b) => a < b ? a : b);
                      for (int i = 0; i < len; i++) {
                        allLabels.add(labels[i]);
                        allXs.add(dataList[i].x);
                      }
                    }
                  }

                  if (allXs.isEmpty || allLabels.isEmpty) return Container();

                  double? leftMostX, rightMostX;
                  String? leftMostLabel, rightMostLabel;

                  for (int i = 0; i < allXs.length; i++) {
                    if (leftMostX == null || allXs[i] < leftMostX) {
                      leftMostX = allXs[i];
                      leftMostLabel = allLabels[i];
                    }
                    if (rightMostX == null || allXs[i] > rightMostX) {
                      rightMostX = allXs[i];
                      rightMostLabel = allLabels[i];
                    }
                  }

                  const tolerance = 0.5;
                  if ((value - (leftMostX ?? 0)).abs() < tolerance) {
                    return Text(leftMostLabel ?? '',
                        style: const TextStyle(fontSize: 12));
                  } else if ((value - (rightMostX ?? 0)).abs() < tolerance) {
                    return Text(rightMostLabel ?? '',
                        style: const TextStyle(fontSize: 12));
                  }

                  return Container();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 70,
                interval:
                    (minY != null && maxY != null) ? (maxY! - minY!) / 5 : null,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${NumberFormat('#.####').format(value.toDouble())}$unitSuffix',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, // Ativa os títulos, mas não mostra
                getTitlesWidget: (value, meta) =>
                    const SizedBox.shrink(), // Oculta o conteúdo
                reservedSize: 20, // Reserva espaço visual
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.black, width: 1),
          ),
          lineBarsData: dataStore.servicesList.values
              .map((serviceName) {
                final visible = dataStore.lineVisibility[serviceName] ?? true;
                final spots = dataMap[serviceName] ?? [];

                if (!visible || spots.isEmpty) return null;

                final colorIndex = dataStore.servicesList.values
                        .toList()
                        .indexOf(serviceName) %
                    listaCores.length;

                return LineChartBarData(
                  show: true,
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  barWidth: 2.5,
                  preventCurveOverShooting: true,
                  color: listaCores[colorIndex],
                  isStrokeCapRound: true,
                  isStrokeJoinRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                );
              })
              .whereType<LineChartBarData>()
              .toList(),
          lineTouchData: LineTouchData(
            touchSpotThreshold: 12,
            handleBuiltInTouches: true,
            distanceCalculator: (a, b) => (a - b).distance,
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 0,
              getTooltipColor: (_) => Colors.white,
              tooltipBorder: const BorderSide(color: Colors.black, width: 1),
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final serviceNames = dataMap.keys.toList();
                  final serviceName = (spot.barIndex >= 0 &&
                          spot.barIndex < serviceNames.length)
                      ? serviceNames[spot.barIndex]
                      : "";
                  final labels = labelMap[serviceName] ?? [];
                  final label =
                      (spot.spotIndex >= 0 && spot.spotIndex < labels.length)
                          ? labels[spot.spotIndex]
                          : "Desconhecido";

                  return LineTooltipItem(
                    '💻${NumberFormat('#.#####').format(spot.y)}$unitSuffix\n$label',
                    TextStyle(
                      color: spot.bar.gradient?.colors.first ??
                          spot.bar.color ??
                          Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (_, indicators) {
              return indicators.map((_) {
                return const TouchedSpotIndicatorData(
                  FlLine(color: Colors.transparent),
                  FlDotData(show: true),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
