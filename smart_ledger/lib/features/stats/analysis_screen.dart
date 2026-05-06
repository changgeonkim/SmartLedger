import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/format_utils.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/expense_provider.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(categoryStatsProvider);
    final totalAsync = ref.watch(expenseTotalProvider);
    final topIncreasedAsync = ref.watch(topIncreasedCategoriesProvider);
    final year = ref.watch(selectedYearProvider);
    final month = ref.watch(selectedMonthProvider);
    final prevMonth = DateTime(year, month - 1).month;

    return statsAsync.when(
      data: (stats) {
        if (stats.isEmpty) {
          return const Center(child: Text('이번 달 지출 내역이 없어요'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 일별 소비 흐름
            const _DailyTrendChart(),
            const SizedBox(height: 24),
            // 도넛 차트
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: stats.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return PieChartSectionData(
                      value: s.total,
                      title: '${(s.ratio * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      color: AppColors.categoryColors[
                          i % AppColors.categoryColors.length],
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            // 총계
            totalAsync.when(
              data: (total) => Center(
                child: Column(
                  children: [
                    const Text('총 지출', style: AppTextStyles.caption),
                    Text(FormatUtils.formatWon(total),
                        style: AppTextStyles.heading2),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (err, st) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            // 카테고리별 목록
            ...stats.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final color =
                  AppColors.categoryColors[i % AppColors.categoryColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                        radius: 8,
                        backgroundColor: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(s.categoryName, style: AppTextStyles.body),
                              Text(FormatUtils.formatWon(s.total),
                                  style: AppTextStyles.body),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: s.ratio,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            // 전월 대비 증가 섹션
            if (topIncreasedAsync.valueOrNull?.isNotEmpty ?? false) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('전월 대비 증가',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        Text('$prevMonth월 → $month월',
                            style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...topIncreasedAsync.valueOrNull!.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(d.categoryName, style: AppTextStyles.body),
                              Text(
                                '+${FormatUtils.formatWon(d.delta)}',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.expense),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _DailyTrendChart extends ConsumerWidget {
  const _DailyTrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyStatsProvider);
    final mode = ref.watch(selectedViewModeProvider);
    final year = ref.watch(selectedYearProvider);
    final month = ref.watch(selectedMonthProvider);

    if (mode == ViewMode.day) return const SizedBox.shrink();

    return dailyAsync.when(
      data: (map) {
        if (map.isEmpty) return const SizedBox.shrink();

        final sorted = map.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final spots =
            sorted.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

        final double maxX;
        final double xInterval;
        final String Function(int) xLabel;

        if (mode == ViewMode.year) {
          maxX = 12.0;
          xInterval = 1.0;
          xLabel = (v) => '$v월';
        } else {
          maxX = DateTime(year, month + 1, 0).day.toDouble();
          xInterval = 5.0;
          xLabel = (v) => '$v일';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '소비 흐름',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: maxX,
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2,
                      dotData: FlDotData(show: mode == ViewMode.year),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: xInterval,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            xLabel(value.toInt()),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _yLabel(value),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFEEEEEE),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primary,
                      getTooltipItems: (spots) => spots
                          .map((s) => LineTooltipItem(
                                FormatUtils.formatWon(s.y),
                                const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 180),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _yLabel(double v) {
    if (v >= 10000) return '${(v / 10000).round()}만';
    if (v >= 1000) return '${(v / 1000).round()}천';
    return v.round().toString();
  }
}
