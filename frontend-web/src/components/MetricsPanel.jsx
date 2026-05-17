import { Zap, DollarSign, Clock, Hash } from 'lucide-react';

export default function MetricsPanel({ metrics }) {
  if (!metrics) return null;

  return (
    <div className="flex gap-4">
      <div className="bg-slate-800/80 border border-slate-700 rounded-lg px-4 py-2 flex items-center space-x-3">
        <Clock className="w-4 h-4 text-emerald-400" />
        <div>
          <div className="text-[10px] uppercase tracking-wider text-slate-500 font-semibold">Duration</div>
          <div className="text-sm font-medium text-slate-200">
            {metrics.total_duration_seconds ? `${metrics.total_duration_seconds.toFixed(2)}s` : '---'}
          </div>
        </div>
      </div>
      
      <div className="bg-slate-800/80 border border-slate-700 rounded-lg px-4 py-2 flex items-center space-x-3">
        <Hash className="w-4 h-4 text-blue-400" />
        <div>
          <div className="text-[10px] uppercase tracking-wider text-slate-500 font-semibold">LLM Calls</div>
          <div className="text-sm font-medium text-slate-200">
            {metrics.total_llm_calls || 0}
          </div>
        </div>
      </div>

      <div className="bg-slate-800/80 border border-slate-700 rounded-lg px-4 py-2 flex items-center space-x-3">
        <Zap className="w-4 h-4 text-purple-400" />
        <div>
          <div className="text-[10px] uppercase tracking-wider text-slate-500 font-semibold">Tokens</div>
          <div className="text-sm font-medium text-slate-200">
            {(metrics.total_input_tokens ?? metrics.total_prompt_tokens ?? 0) + (metrics.total_output_tokens ?? metrics.total_completion_tokens ?? 0)}
          </div>
        </div>
      </div>
    </div>
  );
}
