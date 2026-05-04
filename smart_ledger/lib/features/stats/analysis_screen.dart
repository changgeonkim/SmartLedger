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

    return statsAsync.when(
      data: (stats) {
        if (stats.isEmpty) {
          return const Center(child: Text('이번 달 지출 내역이 없어요'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}
