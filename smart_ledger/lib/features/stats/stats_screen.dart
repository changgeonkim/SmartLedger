import 'package:flutter/material.dart';
import 'analysis_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
      ),
      body: const AnalysisScreen(),
    );
  }
}
