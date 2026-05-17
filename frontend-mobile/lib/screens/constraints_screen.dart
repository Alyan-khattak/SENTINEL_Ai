/// Screen 5: Constraints Screen — Editable sliders for budget, time, etc.
/// Canon: Flutter_Agent.md §5.5

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../theme/app_theme.dart';

class ConstraintsScreen extends StatelessWidget {
  const ConstraintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RunProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SentinelTheme.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SentinelTheme.cyan.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.tune, color: SentinelTheme.cyan),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Action Constraints', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
                      SizedBox(height: 2),
                      Text('Adjust limits before running analysis', style: TextStyle(fontSize: 12, color: SentinelTheme.slate400)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sliderTile(
            title: 'Budget Cap',
            value: prov.budgetMax,
            min: 100000,
            max: 2000000,
            suffix: 'PKR',
            format: (v) => 'PKR ${v.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            onChanged: (v) => prov.updateBudget(v),
          ),

          _sliderTile(
            title: 'Time to Resolution',
            value: prov.timeToResolutionMax,
            min: 12,
            max: 168,
            suffix: 'hours',
            format: (v) => '${v.round()} hours',
            onChanged: (v) => prov.updateTimeToResolution(v),
          ),

          _sliderTile(
            title: 'Notification Deadline',
            value: prov.notificationDeadlineMax,
            min: 0.5,
            max: 12,
            suffix: 'hours',
            format: (v) => '${v.toStringAsFixed(1)} hours',
            onChanged: (v) => prov.updateNotificationDeadline(v),
          ),

          const SizedBox(height: 16),
          const Text('RESOURCE LIMITS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.slate400, letterSpacing: 1.2)),
          const SizedBox(height: 12),

          _counterTile(
            title: 'Warehouse Staff',
            value: prov.warehouseStaff,
            icon: Icons.people,
            onChanged: (v) => prov.updateWarehouseStaff(v),
          ),
          _counterTile(
            title: 'Delivery Trucks',
            value: prov.deliveryTrucks,
            icon: Icons.local_shipping,
            onChanged: (v) => prov.updateDeliveryTrucks(v),
          ),
          _counterTile(
            title: 'API Rate Limit',
            value: prov.apiRateLimit,
            icon: Icons.speed,
            suffix: '/min',
            onChanged: (v) => prov.updateApiRateLimit(v),
          ),
        ],
      ),
    );
  }

  Widget _sliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SentinelTheme.slate800.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: SentinelTheme.slate200, fontSize: 14)),
              Text(format(value), style: const TextStyle(fontWeight: FontWeight.w700, color: SentinelTheme.cyan, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 4,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _counterTile({
    required String title,
    required int value,
    required IconData icon,
    String suffix = '',
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SentinelTheme.slate800.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: SentinelTheme.slate400, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: SentinelTheme.slate200, fontSize: 14))),
          // Minus
          GestureDetector(
            onTap: () => value > 1 ? onChanged(value - 1) : null,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: SentinelTheme.slate700, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.remove, size: 16, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$value$suffix', style: const TextStyle(fontWeight: FontWeight.w700, color: SentinelTheme.cyan, fontSize: 16)),
          ),
          // Plus
          GestureDetector(
            onTap: () => onChanged(value + 1),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: SentinelTheme.cyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.add, size: 16, color: SentinelTheme.cyan),
            ),
          ),
        ],
      ),
    );
  }
}
