import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../features/home/home_screen.dart';
import '../features/expense/expense_list_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/stats/budget_screen.dart';
import '../features/map/map_screen.dart';
import '../providers/navigation_provider.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    ExpenseListScreen(),
    MapScreen(),
    StatsScreen(),
    BudgetScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // 외부에서 탭 전환 요청이 오면 반영
    ref.listen<int>(selectedTabIndexProvider, (_, next) {
      setState(() => _currentIndex = next);
      ref.read(selectedTabIndexProvider.notifier).state = _currentIndex;
    });

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '내역',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '지도',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '통계',
          ),
          NavigationDestination(
            icon: Icon(Icons.wallet_outlined),
            selectedIcon: Icon(Icons.wallet),
            label: '예산',
          ),
        ],
      ),
    );
  }
}
