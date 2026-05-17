import { ArrowRight, TrendingUp, TrendingDown, Minus } from 'lucide-react';

function formatVal(v) {
  if (v === null || v === undefined) return '—';
  if (typeof v === 'boolean') return v ? 'Yes' : 'No';
  if (typeof v === 'number') return v.toLocaleString();
  return String(v);
}

function DiffRow({ label, before, after }) {
  const changed = before !== after;
  const increased = typeof after === 'number' && typeof before === 'number' && after > before;
  const decreased = typeof after === 'number' && typeof before === 'number' && after < before;

  return (
    <div className={`flex items-center justify-between py-2.5 px-3 rounded-lg ${changed ? 'bg-slate-800/50' : 'bg-transparent'}`}>
      <span className="text-xs text-slate-500 w-40 shrink-0 capitalize">{label.replace(/_/g, ' ')}</span>
      <div className="flex items-center space-x-2 flex-1 justify-end">
        <span className="text-xs text-slate-400 font-mono">{formatVal(before)}</span>
        {changed && (
          <>
            <ArrowRight className="w-3 h-3 text-slate-600 shrink-0" />
            <span className={`text-xs font-mono font-semibold ${increased ? 'text-emerald-400' : decreased ? 'text-amber-400' : 'text-blue-400'}`}>
              {formatVal(after)}
            </span>
            {increased && <TrendingUp className="w-3 h-3 text-emerald-400 shrink-0" />}
            {decreased && <TrendingDown className="w-3 h-3 text-amber-400 shrink-0" />}
            {!increased && !decreased && <Minus className="w-3 h-3 text-blue-400 shrink-0" />}
          </>
        )}
      </div>
    </div>
  );
}

export default function StateDiff({ before, after }) {
  if (!before && !after) return null;

  const allKeys = new Set([...Object.keys(before || {}), ...Object.keys(after || {})]);

  return (
    <div>
      <div className="flex items-center space-x-4 mb-3 text-xs text-slate-500">
        <span className="flex items-center space-x-1">
          <span className="w-2 h-2 rounded-full bg-slate-500 inline-block" />
          <span>Before</span>
        </span>
        <ArrowRight className="w-3 h-3" />
        <span className="flex items-center space-x-1">
          <span className="w-2 h-2 rounded-full bg-emerald-500 inline-block" />
          <span>After</span>
        </span>
      </div>
      <div className="space-y-1">
        {[...allKeys].map(key => (
          <DiffRow
            key={key}
            label={key}
            before={before?.[key]}
            after={after?.[key]}
          />
        ))}
      </div>
    </div>
  );
}
