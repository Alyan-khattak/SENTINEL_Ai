/// Screen 6: Execution Screen — Live timeline from WebSocket
/// Canon: Flutter_Agent.md §5.6

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../theme/app_theme.dart';

class ExecutionScreen extends StatelessWidget {
  const ExecutionScreen({super.key});

  static bool _dialogShowing = false;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RunProvider>();
    final steps = prov.executionSteps;

    if (steps.isEmpty && prov.status != 'running') {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 48, color: SentinelTheme.slate600),
            SizedBox(height: 16),
            Text('Waiting for Execution Agent...', style: TextStyle(color: SentinelTheme.slate400)),
          ],
        ),
      );
    }

    // Approval modal check
    if (prov.approvalRequired && !_dialogShowing) {
      _dialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showApprovalDialog(context, prov);
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          _statusBanner(prov),
          const SizedBox(height: 20),

          const Text('EXECUTION LOG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.slate400, letterSpacing: 1.2)),
          const SizedBox(height: 12),

          ...List.generate(steps.length, (i) {
            final step = steps[i];
            return _stepTile(step, i == steps.length - 1 && prov.status == 'running');
          }),
        ],
      ),
    );
  }

  Widget _statusBanner(RunProvider prov) {
    Color color;
    IconData icon;
    String label;

    switch (prov.status) {
      case 'running':
        color = SentinelTheme.blue;
        icon = Icons.sync;
        label = 'Pipeline Running';
        break;
      case 'completed':
        color = SentinelTheme.emerald;
        icon = Icons.check_circle;
        label = 'Pipeline Completed';
        break;
      case 'failed':
        color = SentinelTheme.red;
        icon = Icons.error;
        label = 'Pipeline Failed';
        break;
      default:
        color = SentinelTheme.slate400;
        icon = Icons.hourglass_empty;
        label = 'Idle';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 16)),
          const Spacer(),
          if (prov.currentRunId != null)
            Text(prov.currentRunId!.split('_').last, style: const TextStyle(fontSize: 12, color: SentinelTheme.slate400, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _stepTile(dynamic step, bool isLast) {
    Color statusColor;
    IconData statusIcon;

    switch (step.status) {
      case 'started':
        statusColor = SentinelTheme.blue;
        statusIcon = Icons.play_circle_filled;
        break;
      case 'completed':
        statusColor = SentinelTheme.emerald;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = SentinelTheme.red;
        statusIcon = Icons.cancel;
        break;
      case 'retrying':
        statusColor = SentinelTheme.amber;
        statusIcon = Icons.refresh;
        break;
      case 'rolled_back':
        statusColor = SentinelTheme.purple;
        statusIcon = Icons.undo;
        break;
      default:
        statusColor = SentinelTheme.slate400;
        statusIcon = Icons.circle_outlined;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line + dot
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Icon(statusIcon, size: 12, color: statusColor),
              ),
              if (!isLast)
                Container(width: 2, height: 40, color: SentinelTheme.slate700),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SentinelTheme.slate800.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.actionName.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.w600, color: statusColor, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(step.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ),
                if (step.error != null) ...[
                  const SizedBox(height: 6),
                  Text(step.error!, style: const TextStyle(fontSize: 11, color: SentinelTheme.red)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showApprovalDialog(BuildContext context, RunProvider prov) {
    if (!prov.approvalRequired) return;

    final pending = prov.pendingApproval;
    final impactsData = pending?['predicted_impacts'] as List<dynamic>? ?? [];
    List<dynamic> sideEffectsList = [];
    List<dynamic> alternativePath = [];
    
    if (impactsData.isNotEmpty) {
      final firstImpact = impactsData[0];
      sideEffectsList = firstImpact['impacts'] ?? [];
      alternativePath = firstImpact['alternative_path'] ?? [];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SentinelTheme.slate800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: SentinelTheme.slate600, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: SentinelTheme.amber, size: 32),
                const SizedBox(width: 12),
                const Expanded(child: Text('Approval Required: High Impact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
              ],
            ),
            const SizedBox(height: 16),
            const Text('PREDICTED SIDE EFFECTS', style: TextStyle(color: SentinelTheme.slate400, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            ...sideEffectsList.map((e) {
              final isNegative = e['direction'] == 'negative';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isNegative ? SentinelTheme.red.withValues(alpha: 0.1) : SentinelTheme.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isNegative ? SentinelTheme.red.withValues(alpha: 0.3) : SentinelTheme.emerald.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['area'].toString().toUpperCase(), style: TextStyle(color: isNegative ? SentinelTheme.red : SentinelTheme.emerald, fontSize: 10, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(e['explanation'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              );
            }).toList(),

            if (alternativePath.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('SELECT A WHAT-IF MITIGATION TO APPLY', style: TextStyle(color: SentinelTheme.cyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 8),
              Column(
                children: alternativePath.map((alt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        prov.submitApproval('modify', modification: alt['name']);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SentinelTheme.cyan.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: SentinelTheme.cyan.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.alt_route, color: SentinelTheme.cyan, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alt['description'] ?? 'Mitigation Path',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Est. Cost: PKR ${alt['estimated_cost_pkr'] ?? 0} | Est. Duration: ${((alt['estimated_duration_minutes'] ?? 0) / 60).toStringAsFixed(1)} hrs',
                                    style: const TextStyle(color: SentinelTheme.slate400, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: SentinelTheme.cyan, size: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: SentinelTheme.emerald, foregroundColor: SentinelTheme.deepNavy),
                    onPressed: () { prov.submitApproval('approve'); Navigator.pop(ctx); },
                    child: const Text('Approve Original', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: SentinelTheme.red, foregroundColor: Colors.white),
                    onPressed: () { prov.submitApproval('reject'); Navigator.pop(ctx); },
                    child: const Text('Reject & Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).then((_) {
      _dialogShowing = false;
    });
  }
}
