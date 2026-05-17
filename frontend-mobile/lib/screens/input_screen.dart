/// Screen 1: Input Screen — Start a new analysis run
/// Canon: Flutter_Agent.md §5.1

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../theme/app_theme.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _scenarioController = TextEditingController(text: 'inventory_shortage');
  bool _isSimulatedMode = true;

  final List<Map<String, dynamic>> _simulatedSources = [
    {'icon': '📊', 'label': 'Warehouse Stock (CSV)', 'type': 'csv', 'path': 'mock-data/warehouse_stock_7days.csv'},
    {'icon': '📈', 'label': 'Sales Dashboard (JSON)', 'type': 'json', 'path': 'mock-data/sales_dashboard.json'},
    {'icon': '📝', 'label': 'Customer Complaints (JSON)', 'type': 'json', 'path': 'mock-data/complaints.json'},
    {'icon': '📰', 'label': 'News Feed (JSON)', 'type': 'json', 'path': 'mock-data/news_feed.json'},
    {'icon': '📄', 'label': 'Supplier Email (PDF)', 'type': 'pdf', 'path': 'mock-data/supplier_email.pdf'},
    {'icon': '🗑️', 'label': 'Duplicate/Spam Source', 'type': 'json', 'path': 'mock-data/duplicate_spam_source.json'},
    {'icon': '⏳', 'label': 'Stale/Irrelevant Source', 'type': 'json', 'path': 'mock-data/stale_irrelevant_source.json'},
  ];

  final List<Map<String, dynamic>> _customSources = [];

  late List<bool> _simulatedSelected;
  late List<bool> _customSelected;

  @override
  void initState() {
    super.initState();
    _simulatedSelected = List.generate(_simulatedSources.length, (_) => true);
    _customSelected = [];
  }

  @override
  void dispose() {
    _scenarioController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _selectedSources {
    if (_isSimulatedMode) {
      return [
        for (int i = 0; i < _simulatedSources.length; i++)
          if (_simulatedSelected[i])
            {
              'type': _simulatedSources[i]['type'],
              'path': _simulatedSources[i]['path'],
            }
      ];
    } else {
      return [
        for (int i = 0; i < _customSources.length; i++)
          if (_customSelected[i])
            {
              'type': _customSources[i]['type'],
              'path': _customSources[i]['path'],
              if (_customSources[i].containsKey('raw_content')) 'raw_content': _customSources[i]['raw_content'],
            }
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RunProvider>();
    final selectedCount = _isSimulatedMode
        ? _simulatedSelected.where((s) => s).length
        : _customSelected.where((s) => s).length;
    final totalSourcesCount = _isSimulatedMode ? _simulatedSources.length : _customSources.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SentinelTheme.emerald.withValues(alpha: 0.15),
                  SentinelTheme.blue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SentinelTheme.emerald.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SentinelTheme.emerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.radar, color: SentinelTheme.emerald, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SENTINEL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Configure your analysis run', style: TextStyle(fontSize: 13, color: SentinelTheme.slate400)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Segment Selector Toggle (Simulated vs Custom)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: SentinelTheme.slate800.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isSimulatedMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isSimulatedMode ? SentinelTheme.emerald : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Simulated Data',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _isSimulatedMode ? SentinelTheme.deepNavy : SentinelTheme.slate400,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isSimulatedMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isSimulatedMode ? SentinelTheme.emerald : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Custom Input',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: !_isSimulatedMode ? SentinelTheme.deepNavy : SentinelTheme.slate400,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Scenario Input
          const Text('SCENARIO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.slate400, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          TextField(
            controller: _scenarioController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. inventory_shortage',
              hintStyle: const TextStyle(color: SentinelTheme.slate600),
              prefixIcon: const Icon(Icons.edit_outlined, color: SentinelTheme.slate600, size: 18),
              filled: true,
              fillColor: SentinelTheme.slate800.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: SentinelTheme.emerald),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(height: 24),

          // Sources header
          Row(
            children: [
              const Text('DATA SOURCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.slate400, letterSpacing: 1.2)),
              const Spacer(),
              if (_isSimulatedMode) ...[
                GestureDetector(
                  onTap: () => setState(() {
                    _simulatedSelected = List.generate(_simulatedSources.length, (_) => true);
                    _scenarioController.text = 'inventory_shortage';
                  }),
                  child: const Text(
                    'Reset Defaults',
                    style: TextStyle(fontSize: 11, color: SentinelTheme.amber),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() {
                    final allOn = selectedCount == _simulatedSources.length;
                    _simulatedSelected = List.generate(_simulatedSources.length, (_) => !allOn);
                  }),
                  child: Text(
                    selectedCount == _simulatedSources.length ? 'Deselect All' : 'Select All',
                    style: const TextStyle(fontSize: 11, color: SentinelTheme.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$selectedCount/${_simulatedSources.length}',
                    style: const TextStyle(fontSize: 11, color: SentinelTheme.slate600)),
              ] else ...[
                if (_customSources.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => setState(() {
                      final allOn = selectedCount == _customSources.length;
                      _customSelected = List.generate(_customSources.length, (_) => !allOn);
                    }),
                    child: Text(
                      selectedCount == _customSources.length ? 'Deselect All' : 'Select All',
                      style: const TextStyle(fontSize: 11, color: SentinelTheme.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$selectedCount/${_customSources.length}',
                      style: const TextStyle(fontSize: 11, color: SentinelTheme.slate600)),
                ],
              ],
            ],
          ),
          const SizedBox(height: 12),

          if (!_isSimulatedMode && _customSources.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: SentinelTheme.slate800.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.note_add_outlined, size: 48, color: SentinelTheme.slate600),
                  const SizedBox(height: 12),
                  const Text(
                    'No Custom Sources Added',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap the button below to add your alternate supply email, warehouse IoT feed, or CSV log!',
                    style: TextStyle(color: SentinelTheme.slate400, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            ...List.generate(
              _isSimulatedMode ? _simulatedSources.length : _customSources.length,
              (i) {
                final src = _isSimulatedMode ? _simulatedSources[i] : _customSources[i];
                final on = _isSimulatedMode ? _simulatedSelected[i] : _customSelected[i];
                return GestureDetector(
                  onTap: () => setState(() {
                    if (_isSimulatedMode) {
                      _simulatedSelected[i] = !_simulatedSelected[i];
                    } else {
                      _customSelected[i] = !_customSelected[i];
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: on
                          ? SentinelTheme.emerald.withValues(alpha: 0.08)
                          : SentinelTheme.slate800.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: on
                            ? SentinelTheme.emerald.withValues(alpha: 0.4)
                            : SentinelTheme.slate700.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(src['icon']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      src['label']!,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: on ? Colors.white : SentinelTheme.slate600,
                                      ),
                                    ),
                                  ),
                                  if (src.containsKey('raw_content'))
                                    GestureDetector(
                                      onTap: () => _viewCustomSourceDialog(context, src['label']!, src['raw_content']!),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6),
                                        child: Icon(Icons.visibility, color: SentinelTheme.emerald, size: 18),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                src['path']!,
                                style: const TextStyle(fontSize: 10, color: SentinelTheme.slate600, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: on,
                          onChanged: (v) => setState(() {
                            if (_isSimulatedMode) {
                              _simulatedSelected[i] = v!;
                            } else {
                              _customSelected[i] = v!;
                            }
                          }),
                          activeColor: SentinelTheme.emerald,
                          checkColor: SentinelTheme.deepNavy,
                          side: const BorderSide(color: SentinelTheme.slate600),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 12),
          if (!_isSimulatedMode)
            Center(
              child: TextButton.icon(
                onPressed: _showAddSourceDialog,
                icon: const Icon(Icons.add, color: SentinelTheme.emerald),
                label: const Text('Add Custom Source', style: TextStyle(color: SentinelTheme.emerald)),
              ),
            ),

          const SizedBox(height: 24),

          // Constraint Summary (read-only — adjust on Constraints screen)
          const Text('CONSTRAINT SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SentinelTheme.slate400, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          const Text('Adjust on the Constraints screen', style: TextStyle(fontSize: 11, color: SentinelTheme.slate600)),
          const SizedBox(height: 10),
          _constraintChip('Budget Cap', 'PKR ${_formatNumber(prov.budgetMax.round())}'),
          _constraintChip('Time to Resolution', '${prov.timeToResolutionMax.round()} hrs'),
          _constraintChip('Notification Deadline', '${prov.notificationDeadlineMax.round()} hrs'),
          _constraintChip('API Rate Limit', '${prov.apiRateLimit}/min'),

          const SizedBox(height: 32),

          // Validation hint
          if (selectedCount == 0)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Select at least one data source to run.',
                style: TextStyle(color: SentinelTheme.amber, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),

          // Run Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: (prov.status == 'running' || selectedCount == 0)
                  ? null
                  : () {
                      final raw = _scenarioController.text.trim();
                      final scenario = raw.isEmpty ? 'inventory_shortage' : raw.replaceAll(' ', '_').toLowerCase();
                      prov.startRun(scenario: scenario, sources: _selectedSources);
                    },
              icon: prov.status == 'running'
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 28),
              label: Text(prov.status == 'running' ? 'Pipeline Running...' : 'Run Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SentinelTheme.emerald,
                foregroundColor: SentinelTheme.deepNavy,
                disabledBackgroundColor: SentinelTheme.slate700,
                disabledForegroundColor: SentinelTheme.slate600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          if (prov.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SentinelTheme.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SentinelTheme.red.withValues(alpha: 0.3)),
              ),
              child: Text(prov.error!, style: const TextStyle(color: SentinelTheme.red, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatNumber(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  Widget _constraintChip(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: SentinelTheme.slate800.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: SentinelTheme.slate400, fontSize: 13)),
          Text(value, style: const TextStyle(color: SentinelTheme.cyan, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  void _showAddSourceDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedType = 'json';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: SentinelTheme.deepNavy,
              title: const Text('Add Custom Source', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Source Title (e.g. My Custom Data)',
                        labelStyle: TextStyle(color: SentinelTheme.slate400),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: SentinelTheme.slate600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: SentinelTheme.slate800,
                      items: const [
                        DropdownMenuItem(value: 'json', child: Text('JSON', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'csv', child: Text('CSV', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'web', child: Text('Web / Text', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                      decoration: InputDecoration(
                        labelText: 'Source Type',
                        labelStyle: TextStyle(color: SentinelTheme.slate400),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Raw Content (Paste here)',
                        labelStyle: TextStyle(color: SentinelTheme.slate400),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: SentinelTheme.slate600)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: SentinelTheme.emerald)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: SentinelTheme.slate400)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();
                    if (title.isNotEmpty && content.isNotEmpty) {
                      setState(() {
                        _customSources.insert(0, {
                          'icon': '✨',
                          'label': title,
                          'type': selectedType,
                          'path': 'custom_input_${_customSources.length + 1}',
                          'raw_content': content,
                        });
                        _customSelected.insert(0, true);
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Added '$title' to top of Custom Inputs!"),
                          backgroundColor: SentinelTheme.emerald,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: SentinelTheme.emerald),
                  child: const Text('Add', style: TextStyle(color: SentinelTheme.deepNavy)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _viewCustomSourceDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: SentinelTheme.deepNavy,
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(color: SentinelTheme.slate400, fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: SentinelTheme.emerald)),
            ),
          ],
        );
      },
    );
  }
}
