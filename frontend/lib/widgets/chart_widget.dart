import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:curamind/utils/app_colors.dart';
import 'package:curamind/utils/app_styles.dart';

class ChartWidget extends StatelessWidget {
  final List<BarChartGroupData> barGroups;
  final SideTitles bottomTitles;
  final SideTitles leftTitles;

  const ChartWidget({
    super.key,
    required this.barGroups,
    required this.bottomTitles,
    required this.leftTitles,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: bottomTitles),
          leftTitles: AxisTitles(sideTitles: leftTitles),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border:
              Border.all(color: AppColors.textGrey.withOpacity(0.5), width: 1),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        alignment: BarChartAlignment.spaceAround,
        maxY: 100, // Adjust this based on your data's max Y value
      ),
    );
  }
}
