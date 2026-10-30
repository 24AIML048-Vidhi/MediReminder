import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../providers/dose_log_provider.dart';
import '../utils/formatters.dart';

class AdherenceChart extends StatelessWidget {
  final List<DailyAdherenceData> data;

  const AdherenceChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No adherence data available')),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.only(top: 20, right: 16, left: 0, bottom: 4),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = data[group.x.toInt()];
                return BarTooltipItem(
                  '${Formatters.formatShortDate(item.date)}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${rod.toY.toInt()}% adherence\n(${item.totalDoses} doses)',
                      style: const TextStyle(
                        color: Color(0xFF67E8F9),
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    final item = data[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        Formatters.weekdayName(item.date.weekday),
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (index) {
            final item = data[index];
            final pct = item.percentage.clamp(0.0, 100.0);
            Color barColor = const Color(0xFF10B981); // Green
            if (pct < 50) {
              barColor = const Color(0xFFEF4444); // Red
            } else if (pct < 80) {
              barColor = const Color(0xFFF59E0B); // Amber
            }

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: pct,
                  color: barColor,
                  width: 14,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
