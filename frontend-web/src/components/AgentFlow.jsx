import { CheckCircle2, Circle, AlertCircle, Loader } from 'lucide-react';

const PIPELINE = [
  { key: 'planner_done',       label: 'Planner',          desc: 'Workplan + Task Plan' },
  { key: 'ingestion_done',     label: 'Ingestion',         desc: '5+ Source Types' },
  { key: 'noise_filter_done',  label: 'Noise Filter',      desc: 'Duplicate · Spam · Stale' },
  { key: 'insight_done',       label: 'Insight',           desc: 'Temporal Signals' },
  { key: 'conflict_done',      label: 'Conflict Resolver', desc: 'Credibility Scoring' },
  { key: 'action_planner_done',label: 'Action Planner',    desc: 'Multi-Constraint' },
  { key: 'side_effect_done',   label: 'Side-Effect',       desc: 'What-If Branch' },
  { key: 'run_completed',      label: 'Executor',          desc: 'LangGraph · Retry · Rollback' },
];

function statusFor(agentKey, events) {
  const done = events.some(e => e.event === agentKey);
  if (done) return 'done';
  const failed = events.some(e => e.event === 'run_failed');
  if (failed) {
    // Check if any prior stage completed — if not, this stage may have been the one that failed
    const idx = PIPELINE.findIndex(p => p.key === agentKey);
    const prevDone = idx === 0 ? true : events.some(e => e.event === PIPELINE[idx - 1].key);
    if (prevDone && !done) return 'failed';
  }
  // Infer "running" if the previous stage is done but this one isn't
  const idx = PIPELINE.findIndex(p => p.key === agentKey);
  const prevDone = idx === 0 ? events.some(e => e.event === 'run_started') : events.some(e => e.event === PIPELINE[idx - 1].key);
  if (prevDone && !done) return 'running';
  return 'pending';
}

export default function AgentFlow({ events = [] }) {
  return (
    <div className="space-y-1">
      {PIPELINE.map((stage, idx) => {
        const status = statusFor(stage.key, events);
        return (
          <div key={stage.key} className="flex items-stretch">
            {/* Icon + connector */}
            <div className="flex flex-col items-center w-8 shrink-0">
              <div className={`flex items-center justify-center w-7 h-7 rounded-full border z-10 ${
                status === 'done'    ? 'bg-emerald-500/20 border-emerald-500/60' :
                status === 'running' ? 'bg-blue-500/20 border-blue-500/60' :
                status === 'failed'  ? 'bg-red-500/20 border-red-500/60' :
                'bg-slate-800 border-slate-700'
              }`}>
                {status === 'done'    && <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />}
                {status === 'running' && <Loader className="w-3.5 h-3.5 text-blue-400 animate-spin" />}
                {status === 'failed'  && <AlertCircle className="w-3.5 h-3.5 text-red-400" />}
                {status === 'pending' && <Circle className="w-3.5 h-3.5 text-slate-600" />}
              </div>
              {idx < PIPELINE.length - 1 && (
                <div className={`w-px flex-1 my-0.5 ${status === 'done' ? 'bg-emerald-500/30' : 'bg-slate-700/40'}`} />
              )}
            </div>

            {/* Content */}
            <div className={`ml-3 mb-1 flex-1 py-1.5 px-3 rounded-lg border transition-all ${
              status === 'done'    ? 'bg-emerald-500/5 border-emerald-500/20' :
              status === 'running' ? 'bg-blue-500/8 border-blue-500/30 shadow-[0_0_10px_rgba(59,130,246,0.08)]' :
              status === 'failed'  ? 'bg-red-500/5 border-red-500/20' :
              'bg-transparent border-transparent'
            }`}>
              <div className={`text-sm font-medium ${
                status === 'done'    ? 'text-emerald-300' :
                status === 'running' ? 'text-blue-300' :
                status === 'failed'  ? 'text-red-300' :
                'text-slate-600'
              }`}>
                {stage.label}
              </div>
              <div className="text-xs text-slate-600">{stage.desc}</div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
