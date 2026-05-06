import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'analysis_screen.dart';
import 'budget_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('통계'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '통계'),
              Tab(text: '예산'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
          ),
        ),
        body: const TabBarView(
          children: [
            AnalysisScreen(),
            BudgetScreen(),
          ],
        ),
      ),
    );
  }
}
