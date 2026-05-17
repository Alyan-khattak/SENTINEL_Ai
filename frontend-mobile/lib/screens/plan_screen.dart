/// Screen 2: Plan Screen — Shows WorkPlan and TaskPlan
/// Canon: Flutter_Agent.md §5.2

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../theme/app_theme.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RunProvider>();

    if (prov.taskPlan == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: SentinelTheme.slate600),
            SizedBox(height: 16),
            Text('Waiting for Planner Agent...', style: TextStyle(color: SentinelTheme.slate400)),
            SizedBox(height: 8),
            Text('Start a run from the Input tab', style: TextStyle(color: SentinelTheme.slate600, fontSize: 12)),
          ],
        ),
      );
    }

    final steps = (prov.taskPlan?['tasks'] as List?) ?? [];
    final estLlmCalls = prov.taskPlan?['estimated_llm_calls'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan Before Act banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SentinelTheme.purple.withValues(alpha: 0.15), SentinelTheme.blue.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SentinelTheme.purple.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: SentinelTheme.purple, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Plan Before Act', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('${steps.length} steps planned · Est. $estLlmCalls LLM calls',
                          style: const TextStyle(fontSize: 12, color: SentinelTheme.slate400)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('EXECUTION PLAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.slate400, letterSpacing: 1.2)),
          const SizedBox(height: 12),

          ...List.generate(steps.length, (i) {
            final step = steps[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step number
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: SentinelTheme.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SentinelTheme.blue.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}', style: const TextStyle(color: SentinelTheme.blue, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SentinelTheme.slate800.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step['agent_assigned'] ?? step['agent'] ?? 'Agent', style: const TextStyle(fontWeight: FontWeight.w600, color: SentinelTheme.cyan, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(step['description'] ?? step['task'] ?? '', style: const TextStyle(color: SentinelTheme.slate200, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
