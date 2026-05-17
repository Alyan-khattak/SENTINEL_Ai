import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts';

export default function ContradictionGraph({ noiseAssessments, conflicts }) {
  if (!noiseAssessments?.length) return null;

  const data = noiseAssessments.map(a => ({
    name: a.source_id?.replace('src_', '').replace(/_/g, ' ') || a.source_id,
    score: a.credibility_score ?? 0,
    kept: a.keep_for_analysis,
  }));

  const contradictedMetrics = conflicts?.contradictions?.map(c => c.metric) || [];

  return (
    <div>
      <div className="mb-4">
        <ResponsiveContainer width="100%" height={180}>
          <BarChart data={data} margin={{ top: 4, right: 8, left: -20, bottom: 40 }}>
            <XAxis
              dataKey="name"
              tick={{ fill: '#64748b', fontSize: 10 }}
              angle={-30}
              textAnchor="end"
              interval={0}
            />
            <YAxis domain={[0, 10]} tick={{ fill: '#64748b', fontSize: 10 }} />
            <Tooltip
              contentStyle={{ background: '#1e293b', border: '1px solid #334155', borderRadius: 8 }}
              labelStyle={{ color: '#94a3b8', fontSize: 12 }}
              itemStyle={{ color: '#e2e8f0', fontSize: 12 }}
              formatter={(val, _name, props) => [
                `${val}/10${!props.payload.kept ? ' (rejected)' : ''}`,
                'Credibility',
              ]}
            />
            <Bar dataKey="score" radius={[4, 4, 0, 0]}>
              {data.map((entry, idx) => (
                <Cell
                  key={idx}
                  fill={entry.score >= 7 ? '#10b981' : entry.score >= 4 ? '#f59e0b' : '#ef4444'}
                  opacity={entry.kept ? 1 : 0.45}
                />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      <div className="flex items-center space-x-4 text-xs text-slate-500 mb-4">
        <span className="flex items-center space-x-1"><span className="w-2 h-2 rounded-full bg-emerald-500 inline-block" /><span>High (7-10)</span></span>
        <span className="flex items-center space-x-1"><span className="w-2 h-2 rounded-full bg-amber-500 inline-block" /><span>Medium (4-6)</span></span>
        <span className="flex items-center space-x-1"><span className="w-2 h-2 rounded-full bg-red-500 inline-block" /><span>Low (1-3)</span></span>
        <span className="flex items-center space-x-1"><span className="w-2 h-2 rounded-full bg-slate-600 inline-block" /><span>Rejected</span></span>
      </div>

      {contradictedMetrics.length > 0 && (
        <div>
          <div className="text-xs font-semibold text-amber-400 uppercase tracking-wider mb-2">Conflicting Metrics</div>
          <div className="flex flex-wrap gap-2">
            {contradictedMetrics.map((m, i) => (
              <span key={i} className="px-2 py-1 rounded-md bg-amber-500/10 border border-amber-500/30 text-amber-300 text-xs">
                {m}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
