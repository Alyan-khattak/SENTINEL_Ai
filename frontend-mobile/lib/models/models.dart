/// SENTINEL Dart Models — Mirrors backend Pydantic schemas
/// Canon: idea.md §8, Flutter_Agent.md §7

class Source {
  final String sourceId;
  final String sourceType;
  final dynamic content;
  final Map<String, dynamic>? metadata;
  final String? recordedAt;
  final String? ingestedAt;

  Source({
    required this.sourceId,
    required this.sourceType,
    this.content,
    this.metadata,
    this.recordedAt,
    this.ingestedAt,
  });

  factory Source.fromJson(Map<String, dynamic> json) => Source(
        sourceId: json['source_id'] ?? '',
        sourceType: json['source_type'] ?? '',
        content: json['content'],
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'])
            : null,
        recordedAt: json['recorded_at']?.toString(),
        ingestedAt: json['ingested_at']?.toString(),
      );
}

class NoiseAssessment {
  final String sourceId;
  final bool keepForAnalysis;
  final bool isDuplicate;
  final bool isSpam;
  final bool isStale;
  final bool isIrrelevant;
  final double qualityScore;
  final String reasoning;

  NoiseAssessment({
    required this.sourceId,
    required this.keepForAnalysis,
    this.isDuplicate = false,
    this.isSpam = false,
    this.isStale = false,
    this.isIrrelevant = false,
    this.qualityScore = 0.0,
    this.reasoning = '',
  });

  factory NoiseAssessment.fromJson(Map<String, dynamic> json) => NoiseAssessment(
        sourceId: json['source_id'] ?? '',
        keepForAnalysis: json['keep_for_analysis'] ?? true,
        isDuplicate: json['is_duplicate'] ?? false,
        isSpam: json['is_spam'] ?? false,
        isStale: json['is_stale'] ?? false,
        // backend field is is_relevant (not is_irrelevant)
        isIrrelevant: !(json['is_relevant'] ?? true),
        // backend credibility_score is 1-10; normalize to 0.0-1.0 for display
        qualityScore: (json['credibility_score'] ?? 0) / 10.0,
        // backend field is rejection_reason (not reasoning)
        reasoning: json['rejection_reason'] ?? '',
      );

  List<String> get badges {
    final list = <String>[];
    if (isDuplicate) list.add('Duplicate');
    if (isSpam) list.add('Spam');
    if (isStale) list.add('Stale');
    if (isIrrelevant) list.add('Irrelevant');
    return list;
  }
}

class Insight {
  final String insightId;
  final String sourceId;
  final String metric;
  final String value;
  final String? trend;
  final double? rateOfChange;
  final String? riskSeverity;

  Insight({
    required this.insightId,
    required this.sourceId,
    required this.metric,
    required this.value,
    this.trend,
    this.rateOfChange,
    this.riskSeverity,
  });

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
        insightId: json['insight_id'] ?? '',
        // backend field is source_ids (list), take first element
        sourceId: (json['source_ids'] as List?)?.isNotEmpty == true
            ? json['source_ids'][0].toString()
            : '',
        metric: json['metric'] ?? '',
        // backend field is value (not summary)
        value: json['value']?.toString() ?? '',
        trend: json['trend'],
        rateOfChange: (json['rate_of_change'] as num?)?.toDouble(),
        riskSeverity: json['risk_severity'],
      );
}

class Contradiction {
  final String metric;
  final List<dynamic> conflictingSources;
  final String resolutionReasoning;
  final String? winnerSourceId;

  Contradiction({
    required this.metric,
    required this.conflictingSources,
    required this.resolutionReasoning,
    this.winnerSourceId,
  });

  factory Contradiction.fromJson(Map<String, dynamic> json) => Contradiction(
        metric: json['metric'] ?? '',
        // backend field is conflicting_values (not conflicting_sources)
        conflictingSources: json['conflicting_values'] ?? [],
        // backend field is reasoning (not resolution_reasoning)
        resolutionReasoning: json['reasoning'] ?? '',
        winnerSourceId: json['winner_source_id'],
      );
}

class ConflictResolution {
  final List<Contradiction> contradictions;

  ConflictResolution({required this.contradictions});

  factory ConflictResolution.fromJson(Map<String, dynamic> json) {
    final list = (json['contradictions'] as List?)
            ?.map((e) => Contradiction.fromJson(e))
            .toList() ??
        [];
    return ConflictResolution(contradictions: list);
  }
}

class Action {
  final String actionId;
  final String name;
  final String description;
  final String priority;
  final List<String> constraintViolations;
  final bool isDestructive;

  Action({
    required this.actionId,
    required this.name,
    required this.description,
    required this.priority,
    this.constraintViolations = const [],
    this.isDestructive = false,
  });

  factory Action.fromJson(Map<String, dynamic> json) => Action(
        actionId: json['action_id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        // backend field is urgency_tier (not priority)
        priority: json['urgency_tier'] ?? 'medium',
        constraintViolations:
            List<String>.from(json['constraint_violations'] ?? []),
        isDestructive: json['is_destructive'] ?? false,
      );
}

class ActionStep {
  final int stepNumber;
  final String actionName;
  final String status;
  final String? error;
  final int retried;

  ActionStep({
    required this.stepNumber,
    required this.actionName,
    required this.status,
    this.error,
    this.retried = 0,
  });

  factory ActionStep.fromJson(Map<String, dynamic> json) => ActionStep(
        stepNumber: json['step_number'] ?? 0,
        actionName: json['action_name'] ?? '',
        status: json['status'] ?? '',
        error: json['error'],
        retried: json['retried'] ?? 0,
      );
}

class RunMetrics {
  final double totalDuration;
  final int totalLlmCalls;
  final int totalPromptTokens;
  final int totalCompletionTokens;

  RunMetrics({
    required this.totalDuration,
    required this.totalLlmCalls,
    required this.totalPromptTokens,
    required this.totalCompletionTokens,
  });

  factory RunMetrics.fromJson(Map<String, dynamic> json) => RunMetrics(
        totalDuration: (json['total_duration_seconds'] ?? 0).toDouble(),
        totalLlmCalls: json['total_llm_calls'] ?? 0,
        // backend summary() returns total_input_tokens (not total_prompt_tokens)
        totalPromptTokens: json['total_input_tokens'] ?? 0,
        // backend summary() returns total_output_tokens (not total_completion_tokens)
        totalCompletionTokens: json['total_output_tokens'] ?? 0,
      );
}

class RunReport {
  final String runId;
  final String scenario;
  final String status;
  final Map<String, dynamic>? workPlan;
  final Map<String, dynamic>? taskPlan;
  final List<Source> sources;
  final List<NoiseAssessment> noiseAssessments;
  final List<Insight> insights;
  final ConflictResolution? conflicts;
  final List<Action> actions;
  final List<dynamic>? sideEffects;
  final List<ActionStep> executionLog;
  final RunMetrics? metrics;
  final Map<String, dynamic>? baselineComparison;
  final String? summary;
  final Map<String, dynamic>? beforeState;
  final Map<String, dynamic>? afterState;
  final Map<String, dynamic>? metricDescriptions;

  RunReport({
    required this.runId,
    required this.scenario,
    required this.status,
    this.workPlan,
    this.taskPlan,
    this.sources = const [],
    this.noiseAssessments = const [],
    this.insights = const [],
    this.conflicts,
    this.actions = const [],
    this.sideEffects = const [],
    this.executionLog = const [],
    this.metrics,
    this.baselineComparison,
    this.summary,
    this.beforeState,
    this.afterState,
    this.metricDescriptions,
  });

  factory RunReport.fromJson(Map<String, dynamic> json) => RunReport(
        runId: json['run_id'] ?? '',
        scenario: json['scenario'] ?? '',
        status: json['status'] ?? '',
        workPlan: json['work_plan'] != null
            ? Map<String, dynamic>.from(json['work_plan'])
            : null,
        taskPlan: json['task_plan'] != null
            ? Map<String, dynamic>.from(json['task_plan'])
            : null,
        sources: (json['sources'] as List?)
                ?.map((e) => Source.fromJson(e))
                .toList() ??
            [],
        noiseAssessments: (json['noise_assessments'] as List?)
                ?.map((e) => NoiseAssessment.fromJson(e))
                .toList() ??
            [],
        insights: (json['insights'] as List?)
                ?.map((e) => Insight.fromJson(e))
                .toList() ??
            [],
        conflicts: json['conflicts'] != null
            ? ConflictResolution.fromJson(json['conflicts'])
            : null,
        actions: (json['actions'] as List?)
                ?.map((e) => Action.fromJson(e))
                .toList() ??
            [],
        sideEffects: json['side_effects'] as List?,
        executionLog: (json['execution_log'] as List?)
                ?.map((e) => ActionStep.fromJson(e))
                .toList() ??
            [],
        metrics: json['metrics'] != null
            ? RunMetrics.fromJson(json['metrics'])
            : null,
        baselineComparison: json['baseline_comparison'] != null
            ? Map<String, dynamic>.from(json['baseline_comparison'])
            : null,
        summary: json['summary'],
        beforeState: json['before_state'] != null
            ? Map<String, dynamic>.from(json['before_state'])
            : null,
        afterState: json['after_state'] != null
            ? Map<String, dynamic>.from(json['after_state'])
            : null,
        metricDescriptions: json['metric_descriptions'] != null
            ? Map<String, dynamic>.from(json['metric_descriptions'])
            : null,
      );
}
