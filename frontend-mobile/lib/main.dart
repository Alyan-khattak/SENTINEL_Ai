/// SENTINEL Mobile App — Main Entry Point
/// Canon: Flutter_Agent.md §5, planning.md Hours 16-20

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/run_provider.dart';
import 'screens/input_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/sources_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/constraints_screen.dart';
import 'screens/execution_screen.dart';
import 'screens/outcome_screen.dart';
import 'screens/trace_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => RunProvider(),
      child: const SentinelApp(),
    ),
  );
}

class SentinelApp extends StatelessWidget {
  const SentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SENTINEL',
      theme: SentinelTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _lastStatus;

  static const _screens = [
    InputScreen(),
    PlanScreen(),
    SourcesScreen(),
    AnalysisScreen(),
    ConstraintsScreen(),
    ExecutionScreen(),
    OutcomeScreen(),
    TraceScreen(),
  ];

  static const _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: 'Input'),
    BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Plan'),
    BottomNavigationBarItem(icon: Icon(Icons.source_outlined), label: 'Sources'),
    BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Analysis'),
    BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Constraints'),
    BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Execution'),
    BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Outcome'),
    BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Trace'),
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RunProvider>();

    if (prov.tabIndexOverride != null) {
      final targetTab = prov.tabIndexOverride!;
      prov.tabIndexOverride = null; // consume
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = targetTab;
          });
        }
      });
    }

    if (prov.status != _lastStatus) {
      final targetStatus = prov.status;
      _lastStatus = targetStatus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            if (targetStatus == 'running') {
              _currentIndex = 5;
            } else if (targetStatus == 'completed') {
              _currentIndex = 6;
            }
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SentinelTheme.emerald.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SentinelTheme.emerald.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.radar, color: SentinelTheme.emerald, size: 18),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [SentinelTheme.emerald, SentinelTheme.blue],
              ).createShader(bounds),
              child: const Text('SENTINEL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
            ),
          ],
        ),
        actions: [
          if (prov.status == 'running')
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: SentinelTheme.emerald)),
            ),
          if (prov.status == 'completed')
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.check_circle, color: SentinelTheme.emerald, size: 20),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: SentinelTheme.navy,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: SentinelTheme.emerald,
          unselectedItemColor: SentinelTheme.slate600,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: _navItems,
        ),
      ),
    );
  }
}
