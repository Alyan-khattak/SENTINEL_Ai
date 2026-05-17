/// Screen 8: Trace Screen — Live event timeline + ADK Trace Viewer
/// Canon: Flutter_Agent.md §5.8, idea.md §4 WebSocket events

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TraceScreen extends StatefulWidget {
  const TraceScreen({super.key});

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  int _selectedSegment = 0; // 0 = Live Stream, 1 = ADK Agent Trace

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RunProvider>();
    final events = prov.events;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom Segment Control
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: SentinelTheme.slate800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSegment = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedSegment == 0 ? SentinelTheme.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'LIVE STREAM',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedSegment == 0 ? Colors.white : SentinelTheme.slate400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSegment = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedSegment == 1 ? SentinelTheme.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'ADK AGENT TRACE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedSegment == 1 ? Colors.white : SentinelTheme.slate400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _selectedSegment == 0 ? _buildLiveStream(events) : _buildAdkTrace(prov),
        ),
      ],
    );
  }

  Widget _buildLiveStream(List<RunEvent> events) {
    if (events.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 48, color: SentinelTheme.slate600),
            SizedBox(height: 16),
            Text('No events yet', style: TextStyle(color: SentinelTheme.slate400)),
            SizedBox(height: 8),
            Text('Start a run to see the live trace', style: TextStyle(color: SentinelTheme.slate600, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              const Text('PIPELINE EVENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SentinelTheme.slate400, letterSpacing: 1.2)),
              const Spacer(),
              Text('${events.length} events', style: const TextStyle(fontSize: 11, color: SentinelTheme.blue)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              return _TraceItem(event: event, isLast: isLast, index: index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdkTrace(RunProvider prov) {
    if (prov.loadingTrace) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(SentinelTheme.blue)),
            SizedBox(height: 16),
            Text('Fetching complete agent trace...', style: TextStyle(color: SentinelTheme.slate400)),
          ],
        ),
      );
    }

    if (prov.adkTrace == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_clock, size: 48, color: SentinelTheme.slate600),
              SizedBox(height: 16),
              Text('ADK Agent Trace Offline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 8),
              Text(
                'Complete agent traces are fetched automatically upon successful pipeline completion. Trigger a run to view deep thought logs.',
                textAlign: TextAlign.center,
                style: TextStyle(color: SentinelTheme.slate600, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final trace = prov.adkTrace!;
    final sources = trace['sources'] as List? ?? [];
    final noise = trace['noise_assessments'] as List? ?? [];
    final insights = trace['insights'] as List? ?? [];
    final conflicts = trace['conflicts']?['contradictions'] as List? ?? [];
    final actions = trace['actions'] as List? ?? [];
    final steps = trace['execution_log'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        _adkAgentCard(
          title: '1. Planner Agent',
          subtitle: 'Work & Task orchestration plans',
          icon: Icons.assignment_turned_in_outlined,
          color: SentinelTheme.blue,
          children: [
            _ioBlock(
              input: 'Scenario target (e.g. inventory_shortage) & user constraints',
              output: 'Sequential work plans and task dependency graphs',
              reasoning: 'Analyzes prompt requirements and constraints to construct an optimized task sequence represented as an acyclic graph inside LangGraph.',
            ),
            Text('Scenario Target: ${trace['scenario'] ?? 'N/A'}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        _adkAgentCard(
          title: '2. Ingestion & Noise Filter',
          subtitle: 'Quality grading and noise mitigation',
          icon: Icons.filter_alt_outlined,
          color: SentinelTheme.purple,
          children: [
            _ioBlock(
              input: 'Unstructured/structured documents, CSV logs, supplier emails',
              output: 'Cleaned list of sources graded by credibility score',
              reasoning: 'Runs data through an LLM classifier, analyzing relevance and metadata to filter duplicates, spam, and stale stock telemetry.',
            ),
            Text('Ingested Sources: ${sources.length} total', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...noise.map((n) {
              final score = (n['credibility_score'] ?? 0);
              final isKept = n['keep_for_analysis'] ?? true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '• Source ID: ${n['source_id']}',
                        style: const TextStyle(color: SentinelTheme.slate400, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isKept ? SentinelTheme.emerald.withValues(alpha: 0.15) : SentinelTheme.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isKept ? 'KEPT (Q: $score/10)' : 'REJECTED',
                        style: TextStyle(color: isKept ? SentinelTheme.emerald : SentinelTheme.red, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
        _adkAgentCard(
          title: '3. Insight Extractor',
          subtitle: 'Metric extraction & severity checks',
          icon: Icons.insights,
          color: SentinelTheme.cyan,
          children: [
            _ioBlock(
              input: 'Retained high-credibility operational source texts',
              output: 'Extracted key metrics, values, and severity flags',
              reasoning: 'Parses unstructured text to gather specific telemetry facts (e.g. inventory levels) and assesses critical threat levels.',
            ),
            ...insights.map((ins) {
              final severity = ins['risk_severity'] ?? 'low';
              Color sevColor = SentinelTheme.emerald;
              if (severity == 'high') sevColor = SentinelTheme.red;
              if (severity == 'medium') sevColor = SentinelTheme.amber;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: SentinelTheme.deepNavy.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ins['metric'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('Value: ${ins['value']}', style: const TextStyle(color: SentinelTheme.slate400, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text(severity.toUpperCase(), style: TextStyle(color: sevColor, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
        _adkAgentCard(
          title: '4. Conflict Resolver',
          subtitle: 'Divergent metric triangulation',
          icon: Icons.flaky,
          color: SentinelTheme.amber,
          children: [
            _ioBlock(
              input: 'Contradictory values for the same metric from multiple files',
              output: 'Single resolved factual value with weighted confidence',
              reasoning: 'Compares conflicting stock levels or delay figures by applying a weighted mathematical credibility and temporal recency algorithm.',
            ),
            if (conflicts.isEmpty)
              const Text('No divergent metrics or conflicts identified.', style: TextStyle(color: SentinelTheme.slate400, fontSize: 12))
            else
              ...conflicts.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conflict: ${c['metric']}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Resolution: ${c['reasoning']}', style: const TextStyle(color: SentinelTheme.slate400, fontSize: 11, height: 1.3)),
                      const Divider(color: SentinelTheme.slate700, height: 16),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
        _adkAgentCard(
          title: '5. Action Planner & Side-Effects',
          subtitle: 'Impact analysis & approval gates',
          icon: Icons.psychology,
          color: SentinelTheme.purple,
          children: [
            _ioBlock(
              input: 'Resolved fact telemetry & slidable user constraints',
              output: 'Optimization task sequence & simulated downstream side-effects',
              reasoning: 'Formulates actions that respect constraints, uses Gemini to predict operational side-effects, and generates what-if staggered alternatives.',
            ),
            ...actions.map((act) {
              final isDestructive = act['is_destructive'] ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '• ${act['name'].toString().replaceAll('_', ' ').toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    if (isDestructive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: SentinelTheme.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Text('DESTRUCTIVE', style: TextStyle(color: SentinelTheme.amber, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
        _adkAgentCard(
          title: '6. Execution Engine',
          subtitle: 'State transitions & fallback records',
          icon: Icons.terminal,
          color: SentinelTheme.emerald,
          children: [
            _ioBlock(
              input: 'Approved action plan & mock endpoint credentials',
              output: 'Simulated API logs, state transitions, & fallback execution records',
              reasoning: 'Sequentially issues orders or updates CRM records. Automatically retries transient errors with backoff and rolls back state on hard failures.',
            ),
            ...steps.map((st) {
              final status = st['status'] ?? 'unknown';
              Color col = SentinelTheme.slate400;
              if (status == 'completed') col = SentinelTheme.emerald;
              if (status == 'failed') col = SentinelTheme.red;
              if (status == 'started') col = SentinelTheme.blue;

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('Step ${st['step_number']}: ', style: const TextStyle(color: SentinelTheme.slate400, fontSize: 11)),
                    Expanded(
                      child: Text(
                        st['action_name'].toString().toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    Text(status.toUpperCase(), style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _ioBlock({required String input, required String output, required String reasoning}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📥 Input:   ', style: TextStyle(color: SentinelTheme.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
            Expanded(child: Text(input, style: const TextStyle(color: Colors.white, fontSize: 11))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📤 Output:  ', style: TextStyle(color: SentinelTheme.emerald, fontSize: 11, fontWeight: FontWeight.bold)),
            Expanded(child: Text(output, style: const TextStyle(color: Colors.white, fontSize: 11))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚙️ Reason:  ', style: TextStyle(color: SentinelTheme.purple, fontSize: 11, fontWeight: FontWeight.bold)),
            Expanded(child: Text(reasoning, style: const TextStyle(color: SentinelTheme.slate400, fontSize: 11, height: 1.35))),
          ],
        ),
        const Divider(color: SentinelTheme.slate700, height: 20),
      ],
    );
  }

  Widget _adkAgentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SentinelTheme.slate800.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SentinelTheme.slate700.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: SentinelTheme.slate400, fontSize: 11)),
        iconColor: color,
        collapsedIconColor: SentinelTheme.slate400,
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TraceItem extends StatelessWidget {
  final RunEvent event;
  final bool isLast;
  final int index;

  const _TraceItem({required this.event, required this.isLast, required this.index});

  Color get _color {
    if (event.event.endsWith('_done') || event.event == 'run_completed') return SentinelTheme.emerald;
    if (event.event == 'run_failed' || event.event == 'step_failed') return SentinelTheme.red;
    if (event.event == 'approval_required') return SentinelTheme.amber;
    if (event.event == 'step_retrying') return SentinelTheme.amber;
    return SentinelTheme.blue;
  }

  IconData get _icon {
    if (event.event.endsWith('_done') || event.event == 'run_completed') return Icons.check_circle_outline;
    if (event.event == 'run_failed' || event.event == 'step_failed') return Icons.error_outline;
    if (event.event == 'approval_required') return Icons.warning_amber_rounded;
    if (event.event == 'step_retrying') return Icons.refresh;
    if (event.event == 'run_started') return Icons.play_circle_outline;
    return Icons.radio_button_unchecked;
  }

  String get _title {
    return event.event.replaceAll('_', ' ');
  }

  String? get _detail {
    final d = event.data;
    if (event.event == 'planner_done') {
      final steps = (d['task_plan']?['tasks'] as List?)?.length ?? 0;
      return 'Generated $steps tasks';
    }
    if (event.event == 'noise_filter_done') {
      final kept = (d['kept'] as List?)?.length ?? 0;
      final rejected = (d['rejected'] as List?)?.length ?? 0;
      return 'Kept $kept · Rejected $rejected';
    }
    if (event.event == 'insight_done') {
      final n = (d['insights'] as List?)?.length ?? 0;
      return '$n insights extracted';
    }
    if (event.event == 'action_planner_done') {
      final n = (d['actions'] as List?)?.length ?? 0;
      return '$n actions planned';
    }
    if (event.event == 'approval_required') {
      return 'Action: ${d['action'] ?? ''}';
    }
    if (event.event == 'run_failed') {
      return d['error']?.toString();
    }
    return null;
  }

  String get _time {
    try {
      final dt = DateTime.parse(event.timestamp).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return '$h:$m:$s';
    } catch (_) {
      return event.timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _color.withValues(alpha: 0.5)),
                  ),
                  child: Icon(_icon, color: _color, size: 14),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: SentinelTheme.slate700.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SentinelTheme.slate800.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SentinelTheme.slate700.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _title,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _color),
                        ),
                      ),
                      Text(_time, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: SentinelTheme.slate400)),
                    ],
                  ),
                  if (_detail != null) ...[
                    const SizedBox(height: 4),
                    Text(_detail!, style: const TextStyle(fontSize: 12, color: SentinelTheme.slate400)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
