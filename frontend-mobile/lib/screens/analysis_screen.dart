/// Screen 4: Analysis Screen — Insights + Conflict Resolution
/// Canon: Flutter_Agent.md §5.4

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../theme/app_theme.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RunProvider>();

    if (prov.insights.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: SentinelTheme.slate600),
            SizedBox(height: 16),
            Text('Waiting for Insight Agent...', style: TextStyle(color: SentinelTheme.slate400)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insights header
          const Text('INSIGHTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.cyan, letterSpacing: 1.2)),
          const SizedBox(height: 12),

          ...prov.insights.map((insight) => _insightCard(insight)),

          // Conflict resolution
          if (prov.conflicts != null && prov.conflicts!.contradictions.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('CONFLICT RESOLUTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.amber, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ...prov.conflicts!.contradictions.map((c) => _conflictCard(c)),
          ],
        ],
      ),
    );
  }

  Widget _insightCard(dynamic insight) {
    Color trendColor = SentinelTheme.slate400;
    IconData trendIcon = Icons.trending_flat;
    if (insight.trend == 'falling') {
      trendColor = SentinelTheme.red;
      trendIcon = Icons.trending_down;
    } else if (insight.trend == 'rising') {
      trendColor = SentinelTheme.emerald;
      trendIcon = Icons.trending_up;
    }

    Color? severityColor;
    if (insight.riskSeverity == 'critical') {
      severityColor = SentinelTheme.red;
    } else if (insight.riskSeverity == 'high') {
      severityColor = SentinelTheme.amber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SentinelTheme.slate800.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(insight.metric, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
              ),
              if (severityColor != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: severityColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    insight.riskSeverity!.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: severityColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(insight.value, style: const TextStyle(fontSize: 13, color: SentinelTheme.slate200)),
          if (insight.rateOfChange != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Rate of Change: ', style: TextStyle(fontSize: 11, color: SentinelTheme.slate400)),
                Text(
                  '${insight.rateOfChange! > 0 ? '+' : ''}${insight.rateOfChange!.toStringAsFixed(1)} units/day',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: trendColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _conflictCard(dynamic conflict) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SentinelTheme.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SentinelTheme.amber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: SentinelTheme.amber, size: 18),
              const SizedBox(width: 8),
              Text('Conflict: ${conflict.metric}', style: const TextStyle(fontWeight: FontWeight.w600, color: SentinelTheme.amber)),
            ],
          ),
          const SizedBox(height: 8),
          Text(conflict.resolutionReasoning, style: const TextStyle(fontSize: 12, color: SentinelTheme.slate200)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SentinelTheme.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: SentinelTheme.emerald, size: 14),
                const SizedBox(width: 4),
                Text(
                  conflict.winnerSourceId != null
                      ? 'Winner: ${conflict.winnerSourceId}'
                      : 'Investigation required',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.emerald),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
