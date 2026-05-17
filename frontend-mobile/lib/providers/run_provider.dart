/// SENTINEL RunProvider — Central State Management
/// Canon: Flutter_Agent.md §10

import 'dart:async';
import 'package:flutter/material.dart' hide Action;
import '../models/models.dart';
import '../services/api_service.dart';

class RunProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // State
  String? currentRunId;
  String status = 'idle'; // idle, running, completed, failed
  String? error;

  // Pipeline data populated by WS events
  Map<String, dynamic>? workPlan;
  Map<String, dynamic>? taskPlan;
  List<Source> sources = [];
  List<NoiseAssessment> noiseAssessments = [];
  List<Insight> insights = [];
  ConflictResolution? conflicts;
  List<Action> actions = [];
  List<Map<String, dynamic>> sideEffects = [];
  List<ActionStep> executionSteps = [];
  RunMetrics? metrics;
  Map<String, dynamic>? baselineComparison;
  List<RunEvent> events = [];
  String? summary;
  Map<String, dynamic>? beforeState;
  Map<String, dynamic>? afterState;
  Map<String, dynamic>? metricDescriptions;
  Map<String, dynamic>? adkTrace;
  bool loadingTrace = false;
  int? tabIndexOverride;

  void changeTab(int index) {
    tabIndexOverride = index;
    notifyListeners();
  }

  // Approval state
  bool approvalRequired = false;
  Map<String, dynamic>? pendingApproval;

  // Constraints (user-editable)
  double budgetMax = 500000;
  double timeToResolutionMax = 48;
  double notificationDeadlineMax = 2;
  int apiRateLimit = 10;
  int warehouseStaff = 3;
  int deliveryTrucks = 5;

  StreamSubscription? _wsSub;

  Map<String, dynamic> get constraintsPayload => {
        'budget_pkr_max': budgetMax.round(),
        'time_to_resolution_hours_max': timeToResolutionMax.round(),
        'notification_deadline_hours_max': notificationDeadlineMax.round(),
        'api_rate_limit_per_minute': apiRateLimit,
        'resource_constraints': {
          'warehouse_staff': warehouseStaff,
          'delivery_trucks': deliveryTrucks,
        },
      };

  Future<void> startRun({
    String scenario = 'inventory_shortage',
    List<Map<String, dynamic>>? sources,
  }) async {
    _resetState();
    status = 'running';
    error = null;
    notifyListeners();

    final sourcesToSend = sources ?? [
      {'type': 'csv', 'path': 'mock-data/warehouse_stock_7days.csv'},
      {'type': 'json', 'path': 'mock-data/sales_dashboard.json'},
      {'type': 'json', 'path': 'mock-data/complaints.json'},
      {'type': 'json', 'path': 'mock-data/news_feed.json'},
      {'type': 'json', 'path': 'mock-data/duplicate_spam_source.json'},
      {'type': 'json', 'path': 'mock-data/stale_irrelevant_source.json'},
      {'type': 'pdf', 'path': 'mock-data/supplier_email.pdf'},
    ];

    try {
      final result = await _api.startRun(
        scenario: scenario,
        sources: sourcesToSend,
        constraints: constraintsPayload,
      );

      currentRunId = result['run_id'];
      notifyListeners();

      // Connect WebSocket
      _connectWs(currentRunId!);
    } catch (e) {
      status = 'failed';
      error = e.toString();
      notifyListeners();
    }
  }

  void _connectWs(String runId) {
    _wsSub?.cancel();
    final stream = _api.connectWebSocket(runId);
    _wsSub = stream.listen(
      (event) => _handleEvent(event),
      onError: (e) {
        // Try to fetch the report on WS error
        _fetchReport(runId);
      },
      onDone: () {
        if (status == 'running') {
          _fetchReport(runId);
        }
      },
    );
  }

  void _handleEvent(RunEvent event) {
    events.add(event);

    switch (event.event) {
      case 'run_started':
        status = 'running';
        break;
      case 'planner_done':
        workPlan = event.data['work_plan'];
        taskPlan = event.data['task_plan'];
        break;
      case 'ingestion_done':
        // Backend sends source_ids (strings), not full Source objects.
        // Full sources arrive via the report fetch after run_completed.
        break;
      case 'noise_filter_done':
        // Backend sends noise_assessments as full objects in the array.
        noiseAssessments = (event.data['noise_assessments'] as List?)
                ?.map((e) => NoiseAssessment.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        break;
      case 'insight_done':
        insights = (event.data['insights'] as List?)
                ?.map((e) => Insight.fromJson(e))
                .toList() ??
            [];
        break;
      case 'conflict_done':
        if (event.data['conflict_resolution'] != null) {
          conflicts = ConflictResolution.fromJson(event.data['conflict_resolution']);
        }
        break;
      case 'action_planner_done':
        actions = (event.data['actions'] as List?)
                ?.map((e) => Action.fromJson(e))
                .toList() ??
            [];
        break;
      case 'side_effect_done':
        sideEffects = List<Map<String, dynamic>>.from(event.data['side_effects'] ?? []);
        break;
      case 'approval_required':
        approvalRequired = true;
        pendingApproval = event.data;
        break;
      case 'step_started':
      case 'step_completed':
      case 'step_failed':
      case 'step_retrying':
      case 'step_rolled_back':
        executionSteps.add(ActionStep(
          stepNumber: event.data['step_number'] ?? 0,
          actionName: event.data['action_name'] ?? event.event,
          status: event.event.replaceFirst('step_', ''),
          error: event.data['error'],
          retried: event.data['retry_count'] ?? 0,
        ));
        break;
      case 'run_completed':
        status = 'completed';
        if (event.data['summary'] != null) summary = event.data['summary'];
        if (event.data['before_state'] != null) beforeState = event.data['before_state'];
        if (event.data['after_state'] != null) afterState = event.data['after_state'];
        _fetchReport(currentRunId!);
        break;
      case 'run_failed':
        status = 'failed';
        error = event.data['error'];
        break;
    }
    notifyListeners();
  }

  Future<void> _fetchReport(String runId) async {
    try {
      final report = await _api.getRunReport(runId);
      metrics = report.metrics;
      baselineComparison = report.baselineComparison;
      if (report.workPlan != null) workPlan = report.workPlan;
      if (report.taskPlan != null) taskPlan = report.taskPlan;
      if (report.summary != null) summary = report.summary;
      if (report.beforeState != null) beforeState = report.beforeState;
      if (report.afterState != null) afterState = report.afterState;
      if (report.metricDescriptions != null) metricDescriptions = report.metricDescriptions;
      if (report.status == 'completed') status = 'completed';
      if (sources.isEmpty) sources = report.sources;
      if (insights.isEmpty) insights = report.insights;
      if (actions.isEmpty) actions = report.actions;
      if (sideEffects.isEmpty && report.sideEffects != null) {
        sideEffects = List<Map<String, dynamic>>.from(report.sideEffects!);
      }
      if (conflicts == null) conflicts = report.conflicts;
      notifyListeners();
      // Fetch ADK Trace automatically once completed
      fetchAdkTrace();
    } catch (_) {}
  }

  Future<void> submitApproval(String decision, {String? modification}) async {
    if (currentRunId == null) return;
    final approvalId = pendingApproval?['approval_id'] ?? '';
    
    // Set state immediately to prevent duplicate dialog triggers during network wait
    approvalRequired = false;
    pendingApproval = null;
    notifyListeners();

    await _api.submitApproval(currentRunId!, approvalId, decision, modification: modification);
  }

  void updateBudget(double val) { budgetMax = val; notifyListeners(); }
  void updateTimeToResolution(double val) { timeToResolutionMax = val; notifyListeners(); }
  void updateNotificationDeadline(double val) { notificationDeadlineMax = val; notifyListeners(); }
  void updateApiRateLimit(int val) { apiRateLimit = val; notifyListeners(); }
  void updateWarehouseStaff(int val) { warehouseStaff = val; notifyListeners(); }
  void updateDeliveryTrucks(int val) { deliveryTrucks = val; notifyListeners(); }

  Future<void> fetchAdkTrace() async {
    if (currentRunId == null) return;
    loadingTrace = true;
    notifyListeners();
    try {
      adkTrace = await _api.getAdkTrace(currentRunId!);
    } catch (_) {
      adkTrace = null;
    } finally {
      loadingTrace = false;
      notifyListeners();
    }
  }

  void _resetState() {
    currentRunId = null;
    workPlan = null;
    taskPlan = null;
    sources = [];
    noiseAssessments = [];
    insights = [];
    conflicts = null;
    actions = [];
    sideEffects = [];
    executionSteps = [];
    metrics = null;
    baselineComparison = null;
    summary = null;
    beforeState = null;
    afterState = null;
    metricDescriptions = null;
    adkTrace = null;
    loadingTrace = false;
    events = [];
    approvalRequired = false;
    pendingApproval = null;
    _wsSub?.cancel();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}
