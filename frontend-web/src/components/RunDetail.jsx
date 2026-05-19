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
  const [activeSimulationPath, setActiveSimulationPath] = useState('executed');
  const [expandedAltIdx, setExpandedAltIdx] = useState(null);

  const toggleSteps = (idx) => {
    setExpandedAltIdx(expandedAltIdx === idx ? null : idx);
  };

  const handleSimulate = (pathName) => {
    setActiveSimulationPath(pathName);
  };

  const getSimulatedBefore = (path) => {
    if (path === 'executed' || !report?.side_effects) {
      return report?.before_state || {};
    }
    for (const se of report.side_effects) {
      const alts = se.alternative_path;
      if (alts) {
        for (const alt of alts) {
          if (alt.name === path && alt.simulated_before_state) {
            return alt.simulated_before_state;
          }
        }
      }
    }
    return report?.before_state || {};
  };

  const getSimulatedAfter = (path) => {
    if (path === 'executed' || !report?.side_effects) {
      return report?.after_state || {};
    }
    for (const se of report.side_effects) {
      const alts = se.alternative_path;
      if (alts) {
        for (const alt of alts) {
          if (alt.name === path && alt.simulated_after_state) {
            return alt.simulated_after_state;
          }
        }
      }
    }
    return report?.after_state || {};
  };

  const getAltPaths = () => {
    const paths = [];
    if (report?.side_effects) {
      for (const se of report.side_effects) {
        const alts = se.alternative_path;
        if (alts) {
          for (const alt of alts) {
            paths.push(alt);
          }
        }
      }
    }
    if (paths.length === 0) {
      paths.push({
        name: 'staggered_order',
        description: 'Split emergency procurement volume into 3 smaller batches over 3 days.',
        estimated_cost_pkr: 500000,
        estimated_duration_minutes: 4320,
        pros: 'Extremely stable daily bank balance; avoids immediate liquidity freeze.',
        cons: 'Warehouse reaches safety target 48 hours later than direct path.',
        steps: [
          'Validate current stock in warehouse',
          'Notify procurement department of impending stockout',
          'Place emergency order 1/3 (35% volume)',
          'Place emergency order 2/3 (35% volume)',
          'Place emergency order 3/3 (30% volume)',
          'Update CRM with staggered delivery schedules',
          'Schedule logistics monitoring and tracking'
        ]
      });
      paths.push({
        name: 'regional_supplier_shift',
        description: 'Karachi Bypass: Purchase 40% of procurement volume from nearby regional supplier.',
        estimated_cost_pkr: 450000,
        estimated_duration_minutes: 1440,
        pros: 'Bypasses country-wide transportation strikes; achieves 24-hour dispatch.',
        cons: 'Requires higher freight premium per unit.',
        steps: [
          'Validate current stock in warehouse',
          'Notify procurement department of impending stockout',
          'Place regional emergency order (40% volume from Local supplier)',
          'Place standard emergency order (60% volume from Primary supplier)',
          'Update CRM with regional/primary delivery schedule',
          'Schedule logistics monitoring and tracking'
        ]
      });
      paths.push({
        name: 'express_shipping',
        description: 'Priority courier logistics dispatch with guaranteed express priority slots.',
        estimated_cost_pkr: 580000,
        estimated_duration_minutes: 2160,
        pros: 'Fastest shipping lead-time of 5 days from international hub.',
        cons: 'Highest budget utilization rate.',
        steps: [
          'Validate current stock in warehouse',
          'Notify procurement department of impending stockout',
          'Place Priority Express order (including air-freight premium slot)',
          'Update CRM with express shipping delivery schedule',
          'Schedule logistics monitoring and tracking'
        ]
      });
    }
    return paths;
  };

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
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-base font-semibold text-slate-100 flex items-center space-x-2">
                <ArrowLeftRight className="w-4 h-4 text-emerald-400" />
                <span>
                  State Diff{' '}
                  {activeSimulationPath !== 'executed' && (
                    <span className="text-cyan-400 text-xs font-normal">
                      ({activeSimulationPath.replace(/_/g, ' ')})
                    </span>
                  )}
                </span>
              </h3>
              {activeSimulationPath !== 'executed' && (
                <button
                  onClick={() => setActiveSimulationPath('executed')}
                  className="px-2 py-0.5 text-xs text-slate-400 hover:text-slate-200 border border-slate-700 rounded-md transition-colors"
                >
                  Reset
                </button>
              )}
            </div>
            <StateDiff
              before={getSimulatedBefore(activeSimulationPath)}
              after={getSimulatedAfter(activeSimulationPath)}
            />
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

      {/* Row 4: What-If Scenarios & Alternative Paths */}
      {report && (
        <div className="glass-panel p-6 border-cyan-500/20">
          <h3 className="text-base font-semibold text-cyan-400 flex items-center space-x-2 mb-4">
            <GitBranch className="w-4 h-4" />
            <span>What-If Scenarios & Alternative Paths</span>
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {getAltPaths().map((alt, idx) => {
              const isSimulated = activeSimulationPath === alt.name;
              const isExpanded = expandedAltIdx === idx;
              return (
                <div
                  key={alt.name || idx}
                  className={`p-4 rounded-xl border flex flex-col justify-between transition-all ${
                    isSimulated
                      ? 'bg-cyan-500/5 border-cyan-500/40 shadow-[0_0_15px_rgba(6,182,212,0.1)]'
                      : 'bg-slate-800/40 border-slate-700/40'
                  }`}
                >
                  <div>
                    <div className="flex items-start justify-between">
                      <h4 className="text-sm font-bold text-slate-100 capitalize">
                        {alt.name?.replace(/_/g, ' ') || 'Alternative Path'}
                      </h4>
                      {isSimulated && (
                        <span className="px-2 py-0.5 text-[9px] bg-cyan-500/20 text-cyan-400 border border-cyan-500/30 rounded-md uppercase font-semibold tracking-wider shrink-0 ml-2">
                          Active
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-slate-400 mt-1 leading-relaxed">{alt.description}</p>

                    <div className="grid grid-cols-2 gap-2 mt-3 text-[11px] text-slate-400 border-t border-slate-700/30 pt-2.5">
                      <div>
                        <span className="text-slate-500 block">Est. Cost</span>
                        <span className="text-amber-400 font-medium font-mono">
                          PKR {alt.estimated_cost_pkr?.toLocaleString()}
                        </span>
                      </div>
                      <div>
                        <span className="text-slate-500 block">Est. Duration</span>
                        <span className="text-blue-400 font-medium font-mono">
                          {(alt.estimated_duration_minutes / 60).toFixed(1)} hrs
                        </span>
                      </div>
                    </div>

                    {alt.pros && (
                      <div className="mt-3 text-xs bg-emerald-500/5 border border-emerald-500/10 rounded p-2">
                        <span className="text-emerald-400 font-semibold block text-[9px] uppercase tracking-wider mb-0.5">
                          👍 Key Advantage
                        </span>
                        <span className="text-slate-300 leading-normal">{alt.pros}</span>
                      </div>
                    )}

                    {alt.cons && (
                      <div className="mt-2 text-xs bg-red-500/5 border border-red-500/10 rounded p-2">
                        <span className="text-red-400 font-semibold block text-[9px] uppercase tracking-wider mb-0.5">
                          👎 Downstream Drawback
                        </span>
                        <span className="text-slate-300 leading-normal">{alt.cons}</span>
                      </div>
                    )}

                    {alt.steps && alt.steps.length > 0 && (
                      <div className="mt-4 pt-3 border-t border-slate-700/30">
                        <button
                          onClick={() => toggleSteps(idx)}
                          className="text-xs text-cyan-400 hover:text-cyan-300 flex items-center space-x-1 font-semibold focus:outline-none"
                        >
                          <span>{isExpanded ? 'Hide Suggested Steps' : 'View Suggested Steps'}</span>
                          <span className="text-[10px] font-normal">({alt.steps.length})</span>
                        </button>

                        {isExpanded && (
                          <div className="mt-3 space-y-2.5 pl-0.5">
                            {alt.steps.map((step, sidx) => (
                              <div key={sidx} className="flex items-start space-x-2.5 text-xs">
                                <div className="flex flex-col items-center">
                                  <div className="w-4 h-4 rounded-full bg-cyan-950/60 border border-cyan-500/40 flex items-center justify-center text-[9px] text-cyan-400 font-bold">
                                    {sidx + 1}
                                  </div>
                                  {sidx < alt.steps.length - 1 && (
                                    <div className="w-0.5 h-4 bg-cyan-950/40 mt-1" />
                                  )}
                                </div>
                                <p className="text-slate-300 flex-1 leading-snug pt-0.5">{step}</p>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    )}
                  </div>

                  <div className="mt-4 pt-3 border-t border-slate-700/30 flex justify-end">
                    <button
                      onClick={() => handleSimulate(alt.name)}
                      className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                        isSimulated
                          ? 'bg-slate-700/40 text-slate-500 cursor-default border border-slate-700/30'
                          : 'bg-cyan-500/10 hover:bg-cyan-500/20 text-cyan-400 border border-cyan-500/30'
                      }`}
                      disabled={isSimulated}
                    >
                      {isSimulated ? 'Outcome Active' : 'Simulate Path Outcome'}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
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
