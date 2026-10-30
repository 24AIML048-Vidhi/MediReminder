import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/health_record.dart';
import '../utils/formatters.dart';

class HealthChart extends StatelessWidget {
  final List<HealthRecord> records;
  final String metric; // 'bp', 'glucose', 'weight', 'temperature'

  const HealthChart({super.key, required this.records, required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter and sort chronologically (oldest to newest for plotting)
    final sorted = records.where((r) {
      if (metric == 'bp') return r.systolicBp != null;
      if (metric == 'glucose') return r.bloodGlucose != null;
      if (metric == 'weight') return r.weightKg != null;
      if (metric == 'temperature') return r.temperatureC != null;
      return false;
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (sorted.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No data points recorded yet')),
      );
    }

    final recentRecords = sorted.length > 10
        ? sorted.sublist(sorted.length - 10)
        : sorted;

    List<FlSpot> primarySpots = [];
    List<FlSpot> secondarySpots = [];

    for (int i = 0; i < recentRecords.length; i++) {
      final r = recentRecords[i];
      if (metric == 'bp') {
        if (r.systolicBp != null) {
          primarySpots.add(FlSpot(i.toDouble(), r.systolicBp!.toDouble()));
        }
        if (r.diastolicBp != null) {
          secondarySpots.add(FlSpot(i.toDouble(), r.diastolicBp!.toDouble()));
        }
      } else if (metric == 'glucose') {
        primarySpots.add(FlSpot(i.toDouble(), r.bloodGlucose!));
      } else if (metric == 'weight') {
        primarySpots.add(FlSpot(i.toDouble(), r.weightKg!));
      } else if (metric == 'temperature') {
        primarySpots.add(FlSpot(i.toDouble(), r.temperatureC!));
      }
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 16, right: 16, left: 0, bottom: 4),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
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
                  final idx = value.toInt();
                  if (idx >= 0 && idx < recentRecords.length) {
                    final item = recentRecords[idx];
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        Formatters.formatShortDate(item.dateTime)
                            .split(',')
                            .first,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: primarySpots,
              isCurved: true,
              color: const Color(0xFF4F46E5),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
              ),
            ),
            if (metric == 'bp' && secondarySpots.isNotEmpty)
              LineChartBarData(
                spots: secondarySpots,
                isCurved: true,
                color: const Color(0xFF06B6D4),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
