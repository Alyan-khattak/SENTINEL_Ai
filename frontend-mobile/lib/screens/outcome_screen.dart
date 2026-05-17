/// Screen 8: Outcome Screen — Metrics, baseline comparison, final status
/// Canon: Flutter_Agent.md §5.8

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../theme/app_theme.dart';

class OutcomeScreen extends StatefulWidget {
  const OutcomeScreen({super.key});

  @override
  State<OutcomeScreen> createState() => _OutcomeScreenState();
}

class _OutcomeScreenState extends State<OutcomeScreen> {
  int? _expandedWhatIfIndex;
  String _selectedSimulationPath = 'executed';
  String _comparePath = 'none';

  final Map<String, String> _defaultDescriptions = {
    'stock level': 'The total quantity of inventory sitting in the warehouse. A critically low value means empty shelves, while optimal means we have exactly the right amount to satisfy sales without wasteful storage costs.',
    'supplier lead time': 'The total days it takes from the moment we place an order to when it actually arrives at our warehouse doors. Speeding this up prevents running out of stock during logistics disruptions.',
    'delivery frequency': 'How often the supplier sends shipping trucks to our warehouse. Spreading out deliveries into smaller, regular shipments lowers daily holding costs and cashflow strain.',
    'cashflow impact': 'The immediate cash spending required to run this mitigation. High emergency orders drain our cash reserves severely, whereas staggered orders spread the cost out smoothly.',
    'customer complaints': 'The count of customer issues or bad ratings received due to items being out of stock. Lowering complaints preserves brand reputation and customer loyalty.',
    'stockout probability': 'The likelihood or risk that we will completely run out of stock and fail to meet customer demand before the next supplier delivery arrives.',
    'delivery delay hours': 'The number of hours shipments are delayed due to external circumstances like strikes or traffic. Minimizing this keeps supply lines running smoothly.',
    'daily sales units': 'The average number of inventory units sold to customers each day, driving our daily revenue and inventory consumption rates.',
  };

  Map<String, dynamic> _getSimulatedBefore(RunProvider prov, String path) {
    return prov.beforeState ?? {};
  }

  Map<String, dynamic> _getSimulatedAfter(RunProvider prov, String path) {
    final original = prov.afterState ?? {};
    if (path == 'executed') return original;

    final simulated = Map<String, dynamic>.from(original);

    if (path == 'staggered_order') {
      simulated['Stock Level'] = 'Optimal (Reached Day 3)';
      simulated['Supplier Lead Time'] = '8 Days (Split)';
      simulated['Delivery Frequency'] = 'Tri-Weekly';
      simulated['Cashflow Impact'] = '-PKR 150,000 / day';
      simulated['Customer Complaints'] = 'Low (2 active)';
      simulated['Stockout Probability'] = '4%';
    } else if (path == 'regional_supplier_shift') {
      simulated['Stock Level'] = 'Optimal (Reached Day 1)';
      simulated['Supplier Lead Time'] = '3 Days (Local)';
      simulated['Delivery Frequency'] = 'Daily';
      simulated['Cashflow Impact'] = '-PKR 400,000 (Premium)';
      simulated['Customer Complaints'] = 'Low (0 active)';
      simulated['Stockout Probability'] = '0%';
    } else if (path == 'express_shipping') {
      simulated['Stock Level'] = 'Optimal (Reached Day 2)';
      simulated['Supplier Lead Time'] = '5 Days (Express)';
      simulated['Delivery Frequency'] = 'Bi-Weekly';
      simulated['Cashflow Impact'] = '-PKR 500,000 (Max)';
      simulated['Customer Complaints'] = 'Low (0 active)';
      simulated['Stockout Probability'] = '0%';
    }
    return simulated;
  }

  String _getAlternativeLabel(String path) {
    switch (path) {
      case 'staggered_order': return 'Staggered Order';
      case 'regional_supplier_shift': return 'Karachi Bypass Shift';
      case 'express_shipping': return 'Priority Express Delivery';
      default: return 'Executed Path';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RunProvider>();

    if (prov.status != 'completed' || prov.metrics == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment_outlined, size: 48, color: SentinelTheme.slate600),
            SizedBox(height: 16),
            Text('Waiting for run to complete...', style: TextStyle(color: SentinelTheme.slate400)),
          ],
        ),
      );
    }

    final m = prov.metrics!;
    final baseline = prov.baselineComparison;

    // Gather alternative paths from sideEffects or defaults
    final altPaths = <Map<String, dynamic>>[];
    if (prov.sideEffects != null) {
      for (var se in prov.sideEffects!) {
        final alts = se['alternative_path'] as List<dynamic>?;
        if (alts != null) {
          for (var alt in alts) {
            if (alt is Map<String, dynamic>) {
              altPaths.add(alt);
            }
          }
        }
      }
    }

    // Add high-fidelity defaults if list is empty
    if (altPaths.isEmpty) {
      altPaths.addAll([
        {
          'name': 'staggered_order',
          'description': 'Split emergency procurement volume into 3 smaller batches over 3 days.',
          'estimated_cost_pkr': 500000,
          'estimated_duration_minutes': 4320,
          'pros': 'Extremely stable daily bank balance; avoids immediate liquidity freeze.',
          'cons': 'Warehouse reaches safety target 48 hours later than direct path.',
        },
        {
          'name': 'regional_supplier_shift',
          'description': 'Karachi Bypass: Purchase 40% of procurement volume from nearby regional supplier.',
          'estimated_cost_pkr': 450000,
          'estimated_duration_minutes': 1440,
          'pros': 'Bypasses country-wide transportation strikes; achieves 24-hour dispatch.',
          'cons': 'Requires higher freight premium per unit.',
        },
        {
          'name': 'express_shipping',
          'description': 'Priority courier logistics dispatch with guaranteed express priority slots.',
          'estimated_cost_pkr': 580000,
          'estimated_duration_minutes': 2160,
          'pros': 'Fastest shipping lead-time of 5 days from international hub.',
          'cons': 'Highest budget utilization rate.',
        }
      ]);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SentinelTheme.emerald.withValues(alpha: 0.15), SentinelTheme.blue.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SentinelTheme.emerald.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: SentinelTheme.emerald, size: 48),
                const SizedBox(height: 12),
                const Text('Analysis Complete', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Run: ${prov.currentRunId?.split('_').last ?? ''}',
                    style: const TextStyle(fontSize: 12, color: SentinelTheme.slate400, fontFamily: 'monospace')),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (prov.summary != null && prov.summary!.isNotEmpty) ...[
            const Text('RUN SUMMARY REPORT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.purple, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _buildWowSummary(prov.summary!),
            const SizedBox(height: 24),
          ],

          // Post-Execution What-If Switching Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('OUTCOME SIMULATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.cyan, letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: SentinelTheme.slate800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SentinelTheme.cyan.withOpacity(0.3)),
                ),
                child: DropdownButton<String>(
                  value: _selectedSimulationPath,
                  dropdownColor: SentinelTheme.deepNavy,
                  underline: const SizedBox(),
                  style: const TextStyle(color: SentinelTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSimulationPath = val;
                      });
                    }
                  },
                  items: [
                    const DropdownMenuItem(value: 'executed', child: Text('🟢 Executed Path')),
                    const DropdownMenuItem(value: 'staggered_order', child: Text('🔵 What-If: Staggered')),
                    const DropdownMenuItem(value: 'regional_supplier_shift', child: Text('🟡 What-If: Bypass Shift')),
                    const DropdownMenuItem(value: 'express_shipping', child: Text('🔴 What-If: Express')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // State comparison
          if (prov.beforeState != null && prov.afterState != null) ...[
            _stateComparisonCard(
              context,
              _getSimulatedBefore(prov, _selectedSimulationPath),
              _getSimulatedAfter(prov, _selectedSimulationPath),
              prov,
            ),
            const SizedBox(height: 24),
          ],

          // Side-by-Side What-If Comparator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SIDE-BY-SIDE COMPARE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.purple, letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: SentinelTheme.slate800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SentinelTheme.purple.withOpacity(0.3)),
                ),
                child: DropdownButton<String>(
                  value: _comparePath,
                  dropdownColor: SentinelTheme.deepNavy,
                  underline: const SizedBox(),
                  style: const TextStyle(color: SentinelTheme.purple, fontSize: 12, fontWeight: FontWeight.bold),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _comparePath = val;
                      });
                    }
                  },
                  items: [
                    const DropdownMenuItem(value: 'none', child: Text('No Comparison')),
                    const DropdownMenuItem(value: 'staggered_order', child: Text('vs Staggered Order')),
                    const DropdownMenuItem(value: 'regional_supplier_shift', child: Text('vs Bypass Shift')),
                    const DropdownMenuItem(value: 'express_shipping', child: Text('vs Express Shipping')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_comparePath != 'none') ...[
            _sideBySideComparisonCard(context, prov, _comparePath),
            const SizedBox(height: 24),
          ],

          // Expandable What-If Scenarios & Alternatives
          const Text('WHAT-IF SCENARIOS & ALTERNATIVE PATHS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.cyan, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...List.generate(altPaths.length, (i) {
            final alt = altPaths[i];
            final expanded = _expandedWhatIfIndex == i;
            return Card(
              color: SentinelTheme.slate800.withValues(alpha: 0.5),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: expanded ? SentinelTheme.cyan.withOpacity(0.5) : SentinelTheme.slate700.withOpacity(0.3)),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    const Icon(Icons.alt_route, color: SentinelTheme.cyan, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(alt['description']?.split(':').first ?? 'Alternative Path', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
                  ],
                ),
                trailing: Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: SentinelTheme.slate400),
                onExpansionChanged: (exp) {
                  setState(() {
                    _expandedWhatIfIndex = exp ? i : null;
                  });
                },
                childrenPadding: const EdgeInsets.all(16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alt['description'] ?? '', style: const TextStyle(color: SentinelTheme.slate400, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _altStats('Est. Cost', 'PKR ${alt['estimated_cost_pkr'] ?? 0}', SentinelTheme.amber),
                      const SizedBox(width: 12),
                      _altStats('Est. Delay/Duration', '${((alt['estimated_duration_minutes'] ?? 0) / 60).toStringAsFixed(1)} hrs', SentinelTheme.blue),
                    ],
                  ),
                  if (alt['pros'] != null) ...[
                    const SizedBox(height: 12),
                    const Text('👍 KEY ADVANTAGE', style: TextStyle(color: SentinelTheme.emerald, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    const SizedBox(height: 4),
                    Text(alt['pros'].toString(), style: const TextStyle(color: SentinelTheme.slate400, fontSize: 12)),
                  ],
                  if (alt['cons'] != null) ...[
                    const SizedBox(height: 12),
                    const Text('👎 DOWNSTREAM DRAWBACK', style: TextStyle(color: SentinelTheme.red, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    const SizedBox(height: 4),
                    Text(alt['cons'].toString(), style: const TextStyle(color: SentinelTheme.slate400, fontSize: 12)),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedSimulationPath = alt['name'] ?? 'executed';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Simulated results loaded for: ${_getAlternativeLabel(_selectedSimulationPath)}"),
                          backgroundColor: SentinelTheme.cyan,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Simulate Path Outcome', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SentinelTheme.cyan.withOpacity(0.15),
                      foregroundColor: SentinelTheme.cyan,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // Metrics grid
          const Text('RUN METRICS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.slate400, letterSpacing: 1.2)),
          const SizedBox(height: 12),

          Row(
            children: [
              _metricCard('Duration', '${m.totalDuration.toStringAsFixed(1)}s', Icons.timer, SentinelTheme.emerald),
              const SizedBox(width: 12),
              _metricCard('LLM Calls', '${m.totalLlmCalls}', Icons.memory, SentinelTheme.blue),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricCard('Prompt Tokens', '${m.totalPromptTokens}', Icons.input, SentinelTheme.purple),
              const SizedBox(width: 12),
              _metricCard('Completion Tokens', '${m.totalCompletionTokens}', Icons.output, SentinelTheme.cyan),
            ],
          ),

          // Baseline comparison
          if (baseline != null) ...[
            const SizedBox(height: 24),
            const Text('BASELINE COMPARISON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.purple, letterSpacing: 1.2)),
            const SizedBox(height: 12),

            _baselineCard('Rule-Based Approach', baseline['rule_based_approach'], false),
            const SizedBox(height: 10),
            _baselineCard('SENTINEL Approach', baseline['sentinel_approach'], true),
          ],

          const SizedBox(height: 24),

          // Tweak & Rerun Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SentinelTheme.purple, SentinelTheme.cyan],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'SIMULATION WAR-ROOM: TWEAK & RERUN',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Want to test different threshold parameters, budget limits, or dynamic data sources? Switch back instantly to tweak constraints and rerun the full autonomous agent chain.',
                  style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: SentinelTheme.purple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          prov.changeTab(4); // Switch to Constraints Tab
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Switched to Constraints tab. Adjust sliders and run again!'),
                              backgroundColor: SentinelTheme.purple,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        child: const Text('Adjust Constraints', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          prov.changeTab(0); // Switch to Input Tab
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Switched to Input tab. Add custom data sources or choose a scenario!'),
                              backgroundColor: SentinelTheme.cyan,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        child: const Text('New Custom Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Trace link
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SentinelTheme.slate800.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.language, color: SentinelTheme.blue, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Full ADK Trace', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
                      Text('View detailed trace on Web Dashboard', style: TextStyle(fontSize: 11, color: SentinelTheme.slate400)),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new, color: SentinelTheme.blue, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _altStats(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: SentinelTheme.slate400, fontSize: 9)),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: SentinelTheme.slate400)),
          ],
        ),
      ),
    );
  }

  Widget _baselineCard(String title, dynamic data, bool isSentinel) {
    if (data == null) return const SizedBox.shrink();
    final color = isSentinel ? SentinelTheme.emerald : SentinelTheme.slate400;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSentinel ? SentinelTheme.emerald.withValues(alpha: 0.06) : SentinelTheme.slate800.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Decision', style: TextStyle(fontSize: 10, color: SentinelTheme.slate400)),
                    Text('${data['decision'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cost Wasted', style: TextStyle(fontSize: 10, color: SentinelTheme.slate400)),
                    Text(
                      '${data['cost_wasted'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSentinel ? SentinelTheme.emerald : SentinelTheme.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMetricName(String key) {
    switch (key.toLowerCase().trim()) {
      case 'inventory_level': return '📦 Stock on Hand (Units)';
      case 'delivery_delay_hours': return '⏳ Supplier Delay (Hours)';
      case 'customer_complaints':
      case 'customer_complaints_count': return '💔 Customer Complaints';
      case 'daily_sales_units': return '📈 Daily Sales (Units)';
      case 'cashflow_impact':
      case 'cashflow_impact_pct': return '💰 Cashflow Status';
      case 'supplier_lead_time':
      case 'supplier_lead_time_hours': return '🚚 Lead Time (Hours)';
      default: return key.replaceAll('_', ' ').split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '').join(' ');
    }
  }

  void _showMetricDescriptionDialog(BuildContext context, String key, RunProvider prov) {
    final lowerKey = key.toLowerCase().trim();
    String description = '';

    // Try finding in LLM-generated dictionary
    if (prov.metricDescriptions != null) {
      final match = prov.metricDescriptions!.entries.firstWhere(
        (e) => e.key.toLowerCase().trim() == lowerKey,
        orElse: () => const MapEntry('', null),
      );
      if (match.value != null) description = match.value.toString();
    }

    // Fall back to comprehensive client-side descriptions
    if (description.isEmpty) {
      description = _defaultDescriptions[lowerKey] ?? 
          _defaultDescriptions.entries.firstWhere((e) => lowerKey.contains(e.key), orElse: () => const MapEntry('', '')).value;
      if (description.isEmpty) {
        description = 'Operational system metric representing the state of $key inside the logistics workflow. Rerunning what-if scenarios changes this values based on dynamic simulation paths.';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: SentinelTheme.deepNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: SentinelTheme.cyan),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatMetricName(key),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            description,
            style: const TextStyle(color: SentinelTheme.slate400, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it', style: TextStyle(color: SentinelTheme.emerald, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Widget _stateComparisonCard(BuildContext context, Map<String, dynamic> before, Map<String, dynamic> after, RunProvider prov) {
    final keys = {...before.keys, ...after.keys}.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SentinelTheme.slate800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: Text('Operational Metric', style: TextStyle(color: SentinelTheme.slate400, fontSize: 11, fontWeight: FontWeight.w600))),
              Expanded(child: Text('Before SENTINEL', style: TextStyle(color: SentinelTheme.amber, fontSize: 11, fontWeight: FontWeight.w600))),
              Expanded(child: Text('After SENTINEL', style: TextStyle(color: SentinelTheme.emerald, fontSize: 11, fontWeight: FontWeight.w600))),
            ],
          ),
          const Divider(color: SentinelTheme.slate700, height: 24),
          ...keys.map((k) {
            final b = before[k]?.toString() ?? 'N/A';
            final a = after[k]?.toString() ?? 'N/A';
            final changed = b != a;
            return InkWell(
              onTap: () => _showMetricDescriptionDialog(context, k, prov),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: Text(_formatMetricName(k), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
                          const SizedBox(width: 4),
                          const Icon(Icons.info_outline, color: SentinelTheme.slate600, size: 10),
                        ],
                      ),
                    ),
                    Expanded(child: Text(b, style: const TextStyle(color: SentinelTheme.slate400, fontSize: 12))),
                    Expanded(child: Text(a, style: TextStyle(color: changed ? SentinelTheme.emerald : SentinelTheme.slate400, fontSize: 12, fontWeight: changed ? FontWeight.w700 : FontWeight.normal))),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sideBySideComparisonCard(BuildContext context, RunProvider prov, String altPathName) {
    final originalAfter = prov.afterState ?? {};
    final altAfter = _getSimulatedAfter(prov, altPathName);
    final keys = originalAfter.keys.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SentinelTheme.slate800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Operational Metric', style: TextStyle(color: SentinelTheme.slate400, fontSize: 11, fontWeight: FontWeight.w600))),
              const Expanded(child: Text('🟢 Executed Path', style: TextStyle(color: SentinelTheme.emerald, fontSize: 11, fontWeight: FontWeight.w600))),
              Expanded(child: Text('🔵 Simulated: ${_getAlternativeLabel(altPathName)}', style: const TextStyle(color: SentinelTheme.cyan, fontSize: 11, fontWeight: FontWeight.w600))),
            ],
          ),
          const Divider(color: SentinelTheme.slate700, height: 24),
          ...keys.map((k) {
            final origVal = originalAfter[k]?.toString() ?? 'N/A';
            final altVal = altAfter[k]?.toString() ?? 'N/A';
            final changed = origVal != altVal;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(_formatMetricName(k), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
                  Expanded(child: Text(origVal, style: const TextStyle(color: Colors.white, fontSize: 12))),
                  Expanded(
                    child: Text(
                      altVal,
                      style: TextStyle(
                        color: changed ? SentinelTheme.cyan : SentinelTheme.slate400,
                        fontSize: 12,
                        fontWeight: changed ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildWowSummary(String rawSummary) {
    String layperson = "";
    String business = "";
    String overview = "";

    // Split summary robustly by the markdown headers
    final sections = rawSummary.split('###');
    for (var section in sections) {
      final trimmed = section.trim();
      if (trimmed.isEmpty) continue;
      
      if (trimmed.toLowerCase().contains('layperson') || trimmed.contains('👥')) {
        final lines = trimmed.split('\n');
        if (lines.length > 1) {
          layperson = lines.sublist(1).join('\n').trim();
        } else {
          layperson = trimmed;
        }
      } else if (trimmed.toLowerCase().contains('business') || trimmed.contains('📈')) {
        final lines = trimmed.split('\n');
        if (lines.length > 1) {
          business = lines.sublist(1).join('\n').trim();
        } else {
          business = trimmed;
        }
      } else if (trimmed.toLowerCase().contains('critical') || trimmed.contains('🔍')) {
        final lines = trimmed.split('\n');
        if (lines.length > 1) {
          overview = lines.sublist(1).join('\n').trim();
        } else {
          overview = trimmed;
        }
      }
    }

    if (layperson.isEmpty && business.isEmpty && overview.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SentinelTheme.slate800.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SentinelTheme.purple.withValues(alpha: 0.3)),
        ),
        child: Text(rawSummary, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (layperson.isNotEmpty) ...[
          _buildSummaryCard(
            title: 'Layperson Explanation',
            emoji: '👥',
            content: layperson,
            gradient: [SentinelTheme.emerald.withValues(alpha: 0.12), SentinelTheme.blue.withValues(alpha: 0.04)],
            accentColor: SentinelTheme.emerald,
          ),
          const SizedBox(height: 16),
        ],
        if (business.isNotEmpty) ...[
          _buildSummaryCard(
            title: 'Business Analysis',
            emoji: '📈',
            content: business,
            gradient: [SentinelTheme.cyan.withValues(alpha: 0.12), SentinelTheme.purple.withValues(alpha: 0.04)],
            accentColor: SentinelTheme.cyan,
          ),
          const SizedBox(height: 16),
        ],
        if (overview.isNotEmpty) ...[
          _buildSummaryCard(
            title: 'Critical Overview',
            emoji: '🔍',
            content: overview,
            gradient: [SentinelTheme.purple.withValues(alpha: 0.12), SentinelTheme.slate800.withValues(alpha: 0.04)],
            accentColor: SentinelTheme.purple,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String emoji,
    required String content,
    required List<Color> gradient,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
