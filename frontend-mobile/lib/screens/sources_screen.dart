/// Screen 3: Sources Screen — Ingested + Noise Filter results
/// Canon: Flutter_Agent.md §5.3

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../theme/app_theme.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RunProvider>();
    final assessments = prov.noiseAssessments;

    if (assessments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list, size: 48, color: SentinelTheme.slate600),
            SizedBox(height: 16),
            Text('Waiting for Noise Filter...', style: TextStyle(color: SentinelTheme.slate400)),
          ],
        ),
      );
    }

    final kept = assessments.where((a) => a.keepForAnalysis).toList();
    final rejected = assessments.where((a) => !a.keepForAnalysis).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary bar
          Row(
            children: [
              _statChip('${kept.length}', 'Kept', SentinelTheme.emerald),
              const SizedBox(width: 12),
              _statChip('${rejected.length}', 'Rejected', SentinelTheme.red),
            ],
          ),
          const SizedBox(height: 20),

          if (kept.isNotEmpty) ...[
            const Text('KEPT SOURCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.emerald, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            ...kept.map((a) => _sourceCard(context, a, kept: true, prov: prov)),
            const SizedBox(height: 20),
          ],

          if (rejected.isNotEmpty) ...[
            const Text('REJECTED SOURCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.red, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            ...rejected.map((a) => _sourceCard(context, a, kept: false, prov: prov)),
          ],
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _sourceCard(BuildContext context, dynamic assessment, {required bool kept, required RunProvider prov}) {
    final a = assessment;
    dynamic sourceObj;
    for (final s in prov.sources) {
      if (s.sourceId == a.sourceId) {
        sourceObj = s;
        break;
      }
    }

    return InkWell(
      onTap: () => _showSourceDetailsDialog(context, a, sourceObj),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kept
              ? SentinelTheme.slate800.withValues(alpha: 0.5)
              : SentinelTheme.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: kept
                ? SentinelTheme.slate700.withValues(alpha: 0.5)
                : SentinelTheme.red.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  kept ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: kept ? SentinelTheme.emerald : SentinelTheme.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.sourceId,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kept ? Colors.white : SentinelTheme.slate400,
                      decoration: kept ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.info_outline, color: SentinelTheme.slate400, size: 14),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SentinelTheme.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(a.qualityScore * 100).round()}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SentinelTheme.blue),
                  ),
                ),
              ],
            ),
            if (!kept && a.badges.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: a.badges.map<Widget>((b) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: SentinelTheme.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: SentinelTheme.amber.withValues(alpha: 0.3)),
                      ),
                      child: Text(b, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: SentinelTheme.amber)),
                    )).toList(),
              ),
            ],
            if (a.reasoning.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(a.reasoning, style: const TextStyle(fontSize: 12, color: SentinelTheme.slate400)),
            ],
          ],
        ),
      ),
    );
  }

  void _showSourceDetailsDialog(BuildContext context, dynamic assessment, dynamic sourceObj) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: SentinelTheme.deepNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.description, color: SentinelTheme.cyan),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  assessment.sourceId,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxHeight: 380),
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Decision', assessment.keepForAnalysis ? 'Kept' : 'Rejected', assessment.keepForAnalysis ? SentinelTheme.emerald : SentinelTheme.red),
                  _detailRow('Quality score', '${(assessment.qualityScore * 100).round()}%', SentinelTheme.blue),
                  if (sourceObj != null && sourceObj.sourceType.isNotEmpty)
                    _detailRow('Source type', sourceObj.sourceType.toUpperCase(), SentinelTheme.purple),
                  const SizedBox(height: 16),
                  const Text('FILTER REASONING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: SentinelTheme.slate400, letterSpacing: 1.1)),
                  const SizedBox(height: 6),
                  Text(
                    assessment.reasoning.isNotEmpty ? assessment.reasoning : 'Passed noise analysis filters. High operational relevance.',
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                  ),
                  if (sourceObj != null && sourceObj.content != null) ...[
                    const SizedBox(height: 20),
                    const Text('INGESTED CONTENT PREVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: SentinelTheme.cyan, letterSpacing: 1.1)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SentinelTheme.slate800,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: SentinelTheme.slate700),
                      ),
                      child: Text(
                        sourceObj.content.toString(),
                        style: const TextStyle(color: SentinelTheme.slate400, fontSize: 11, fontFamily: 'monospace', height: 1.4),
                      ),
                    ),
                  ],
                  if (sourceObj != null && sourceObj.metadata != null && sourceObj.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('METADATA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: SentinelTheme.purple, letterSpacing: 1.1)),
                    const SizedBox(height: 8),
                    ...sourceObj.metadata!.entries.map<Widget>((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: '${e.key}: ', style: const TextStyle(color: SentinelTheme.slate400, fontSize: 11, fontWeight: FontWeight.w600)),
                                TextSpan(text: '${e.value}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: SentinelTheme.emerald, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: SentinelTheme.slate400, fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
