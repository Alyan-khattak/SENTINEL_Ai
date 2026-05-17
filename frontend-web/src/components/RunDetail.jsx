import { useState, useEffect } from 'react';
import { getRunReport, submitApproval } from '../api';
import { Activity, AlertTriangle, BarChart3, GitBranch, Layers, ArrowLeftRight } from 'lucide-react';
import TraceTimeline from './TraceTimeline';
import MetricsPanel from './MetricsPanel';
import AgentFlow from './AgentFlow';
import ContradictionGraph from './ContradictionGraph';
import StateDiff from './StateDiff';

export default function RunDetail({ runId }) {
  const [report, setReport] = useState(null);
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [wsRef, setWsRef] = useState(null);

  useEffect(() => {
    setReport(null);
    setEvents([]);
    setLoading(true);
    if (wsRef) wsRef.close();

    const connectWebSocket = () => {
      const wsBase = import.meta.env.VITE_WS_BASE_URL || 'ws://localhost:8001';
      const ws = new WebSocket(`${wsBase}/ws/runs/${runId}`);
      ws.onmessage = (msg) => {
        const payload = JSON.parse(msg.data);
        setEvents(prev => [...prev, payload]);
        if (payload.event === 'run_completed' || payload.event === 'run_failed') {
          setTimeout(async () => {
            try {
              const data = await getRunReport(runId);
              setReport(data);
            } catch (_) {}
          }, 1000);
        }
      };
      setWsRef(ws);
    };

    const fetchInitial = async () => {
      try {
        const data = await getRunReport(runId);
        setReport(data);
        setLoading(false);
        // Still connect WS in case it's still running
        if (data.status !== 'completed' && data.status !== 'failed') {
          connectWebSocket();
        }
      } catch (_) {
        setLoading(false);
        connectWebSocket();
      }
    };

    fetchInitial();
    return () => { if (wsRef) wsRef.close(); };
  }, [runId]);

  const handleApprove = async (approvalId, decision) => {
    await submitApproval(runId, { approval_id: approvalId, decision });
    setEvents(prev => prev.filter(e => !(e.event === 'approval_required' && e.data.approval_id === approvalId)));
  };

  if (loading && events.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-96 text-slate-400">
        <div className="w-8 h-8 rounded-full border-2 border-emerald-500 border-t-transparent animate-spin mb-4" />
        <p>Loading run details...</p>
      </div>
    );
  }

  const pendingApproval = events.find(e => e.event === 'approval_required');
  const isRunning = !report || (report.status !== 'completed' && report.status !== 'failed');

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="glass-panel p-6 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-slate-100 flex items-center space-x-3">
            <span>Run:</span>
            <span className="font-mono text-blue-400">{runId.split('_').slice(-1)}</span>
            {report?.status === 'completed' && (
              <span className="px-2 py-1 text-xs bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 rounded-md">Completed</span>
            )}
            {report?.status === 'failed' && (
              <span className="px-2 py-1 text-xs bg-red-500/20 text-red-400 border border-red-500/30 rounded-md">Failed</span>
            )}
            {isRunning && (
              <span className="px-2 py-1 text-xs bg-blue-500/20 text-blue-400 border border-blue-500/30 rounded-md animate-pulse">Running</span>
            )}
          </h2>
          <p className="text-slate-400 mt-1 capitalize">
            Scenario: {report?.scenario?.replace(/_/g, ' ') || events[0]?.data?.scenario?.replace(/_/g, ' ') || 'Unknown'}
          </p>
        </div>
        {report?.metrics && <MetricsPanel metrics={report.metrics} />}
      </div>

      {/* Approval Gate */}
      {pendingApproval && (
        <div className="bg-amber-500/10 border border-amber-500/50 rounded-xl p-6 shadow-[0_0_20px_rgba(245,158,11,0.1)]">
          <div className="flex items-start space-x-4">
            <AlertTriangle className="w-6 h-6 text-amber-500 shrink-0 mt-1" />
            <div className="flex-1">
              <h3 className="text-lg font-semibold text-amber-400">Action Approval Required</h3>
              <p className="text-slate-300 mt-1">
                Action flagged for review:{' '}
                <span className="font-mono text-amber-300 bg-amber-500/20 px-1 rounded">
                  {pendingApproval.data.action}
                </span>
              </p>
              <div className="mt-4 flex space-x-3">
                <button
                  onClick={() => handleApprove(pendingApproval.data.approval_id, 'approve')}
                  className="px-4 py-2 bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-400 border border-emerald-500/50 rounded-lg transition-colors text-sm"
                >
                  Approve
                </button>
                <button
                  onClick={() => handleApprove(pendingApproval.data.approval_id, 'reject')}
                  className="px-4 py-2 bg-red-500/20 hover:bg-red-500/30 text-red-400 border border-red-500/50 rounded-lg transition-colors text-sm"
                >
                  Reject
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Row 1: Agent Flow + Execution Timeline */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="glass-panel p-6">
          <h3 className="text-base font-semibold text-slate-100 flex items-center space-x-2 mb-4">
            <GitBranch className="w-4 h-4 text-purple-400" />
            <span>Agent Pipeline</span>
          </h3>
          <AgentFlow events={events} />
        </div>

        <div className="glass-panel p-6">
          <h3 className="text-base font-semibold text-slate-100 flex items-center space-x-2 mb-4">
            <Activity className="w-4 h-4 text-blue-400" />
            <span>Execution Timeline</span>
          </h3>
          <TraceTimeline events={events} report={report} />
        </div>
      </div>

      {/* Row 2: Credibility Graph + Conflicts */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {report?.noise_assessments?.length > 0 && (
          <div className="glass-panel p-6">
            <h3 className="text-base font-semibold text-slate-100 flex items-center space-x-2 mb-4">
              <BarChart3 className="w-4 h-4 text-cyan-400" />
              <span>Source Credibility</span>
            </h3>
            <ContradictionGraph
              noiseAssessments={report.noise_assessments}
              conflicts={report.conflicts}
            />
          </div>
        )}

        {report?.conflicts?.contradictions?.length > 0 && (
          <div className="glass-panel p-6 border-amber-500/20">
            <h3 className="text-base font-semibold text-amber-400 flex items-center space-x-2 mb-4">
              <AlertTriangle className="w-4 h-4" />
              <span>Resolved Conflicts</span>
            </h3>
            <div className="space-y-3">
              {report.conflicts.contradictions.map((c, i) => (
                <div key={i} className="bg-slate-800/50 rounded-lg p-4 border border-slate-700/50">
                  <div className="text-sm font-medium text-slate-200 mb-1">Metric: {c.metric}</div>
                  <div className="text-xs text-slate-400 mb-2">{c.resolution_reasoning}</div>
                  {c.resolved_value && (
                    <div className="text-emerald-400 font-medium text-sm border-t border-slate-700 pt-2">
                      Resolved: {c.resolved_value}
                    </div>
                  )}
                  {c.winner_source_id && (
                    <div className="text-blue-400 text-xs mt-1">Winner source: {c.winner_source_id}</div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Row 3: State Diff + Baseline Comparison */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {(report?.before_state || report?.after_state) && (
          <div className="glass-panel p-6">
            <h3 className="text-base font-semibold text-slate-100 flex items-center space-x-2 mb-4">
              <ArrowLeftRight className="w-4 h-4 text-emerald-400" />
              <span>State Diff</span>
            </h3>
            <StateDiff before={report.before_state} after={report.after_state} />
          </div>
        )}

        {report?.baseline_comparison && (
          <div className="glass-panel p-6 border-purple-500/20">
            <h3 className="text-base font-semibold text-purple-400 flex items-center space-x-2 mb-4">
              <Layers className="w-4 h-4" />
              <span>Baseline Comparison</span>
            </h3>
            <div className="space-y-3">
              <ComparisonRow title="Naive Approach" data={report.baseline_comparison.naive_approach} />
              <ComparisonRow title="Rule-Based" data={report.baseline_comparison.rule_based_approach} />
              <ComparisonRow title="SENTINEL" data={report.baseline_comparison.sentinel_approach} highlight />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function ComparisonRow({ title, data, highlight }) {
  return (
    <div className={`p-3 rounded-lg border ${highlight ? 'bg-purple-500/10 border-purple-500/30' : 'bg-slate-800/50 border-slate-700/50'}`}>
      <div className={`text-sm font-medium ${highlight ? 'text-purple-300' : 'text-slate-400'} mb-2`}>{title}</div>
      <div className="grid grid-cols-2 gap-3 text-xs">
        <div>
          <span className="text-slate-500 block mb-1">Decision</span>
          <span className="text-slate-200">{data?.decision || '—'}</span>
        </div>
        <div>
          <span className="text-slate-500 block mb-1">Cost Wasted</span>
          <span className={highlight ? 'text-emerald-400 font-semibold' : 'text-slate-300'}>{data?.cost_wasted || '—'}</span>
        </div>
      </div>
    </div>
  );
}
