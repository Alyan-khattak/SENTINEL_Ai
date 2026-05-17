import { useState, useEffect } from 'react';
import { getRuns, startRun } from './api';
import RunDetail from './components/RunDetail';
import { Activity, Play, CheckCircle2, XCircle, Clock, X, Settings } from 'lucide-react';

const ALL_SOURCES = [
  { id: 'csv',     icon: '📊', label: 'Warehouse Stock (CSV)',       type: 'csv',  path: 'mock-data/warehouse_stock_7days.csv' },
  { id: 'sales',   icon: '📈', label: 'Sales Dashboard (JSON)',       type: 'json', path: 'mock-data/sales_dashboard.json' },
  { id: 'comp',    icon: '📝', label: 'Customer Complaints (JSON)',   type: 'json', path: 'mock-data/complaints.json' },
  { id: 'news',    icon: '📰', label: 'News Feed (JSON)',              type: 'json', path: 'mock-data/news_feed.json' },
  { id: 'pdf',     icon: '📄', label: 'Supplier Email (PDF)',          type: 'pdf',  path: 'mock-data/supplier_email.pdf' },
  { id: 'spam',    icon: '🗑️', label: 'Duplicate/Spam Source',        type: 'json', path: 'mock-data/duplicate_spam_source.json' },
  { id: 'stale',   icon: '⏳', label: 'Stale/Irrelevant Source',      type: 'json', path: 'mock-data/stale_irrelevant_source.json' },
];

function ConfigModal({ onClose, onStart }) {
  const [scenario, setScenario] = useState('inventory_shortage');
  const [selected, setSelected] = useState(() => new Set(ALL_SOURCES.map(s => s.id)));
  const [budget, setBudget] = useState(500000);
  const [timeRes, setTimeRes] = useState(48);
  const [rateLimit, setRateLimit] = useState(10);
  const [loading, setLoading] = useState(false);

  const toggle = (id) => setSelected(prev => {
    const next = new Set(prev);
    next.has(id) ? next.delete(id) : next.add(id);
    return next;
  });

  const handleStart = async () => {
    if (selected.size === 0) return;
    setLoading(true);
    const sources = ALL_SOURCES.filter(s => selected.has(s.id)).map(s => ({ type: s.type, path: s.path }));
    const raw = scenario.trim().replace(/\s+/g, '_').toLowerCase();
    await onStart({
      scenario: raw || 'inventory_shortage',
      sources,
      constraints: {
        budget_pkr_max: budget,
        time_to_resolution_hours_max: timeRes,
        notification_deadline_hours_max: 2,
        api_rate_limit_per_minute: rateLimit,
        resource_constraints: { warehouse_staff: 3, delivery_trucks: 5 },
      },
    });
    setLoading(false);
  };

  return (
    <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="w-full max-w-lg bg-slate-900 border border-slate-700/60 rounded-2xl shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-800">
          <div className="flex items-center space-x-3">
            <Settings className="w-5 h-5 text-emerald-400" />
            <h2 className="font-semibold text-slate-100">Configure Analysis Run</h2>
          </div>
          <button onClick={onClose} className="text-slate-500 hover:text-slate-300 transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="px-6 py-5 space-y-6 max-h-[75vh] overflow-y-auto">
          {/* Scenario */}
          <div>
            <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Scenario</label>
            <input
              type="text"
              value={scenario}
              onChange={e => setScenario(e.target.value)}
              placeholder="e.g. inventory_shortage"
              className="w-full bg-slate-800/50 border border-slate-700/50 rounded-lg px-4 py-2.5 text-sm text-slate-200 placeholder-slate-600 focus:outline-none focus:border-emerald-500/60 transition-colors"
            />
          </div>

          {/* Sources */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Data Sources</label>
              <button
                onClick={() => setSelected(selected.size === ALL_SOURCES.length ? new Set() : new Set(ALL_SOURCES.map(s => s.id)))}
                className="text-xs text-blue-400 hover:text-blue-300"
              >
                {selected.size === ALL_SOURCES.length ? 'Deselect All' : 'Select All'}
              </button>
            </div>
            <div className="space-y-2">
              {ALL_SOURCES.map(src => (
                <label
                  key={src.id}
                  className={`flex items-center space-x-3 p-3 rounded-lg border cursor-pointer transition-all ${
                    selected.has(src.id)
                      ? 'bg-emerald-500/8 border-emerald-500/30'
                      : 'bg-slate-800/30 border-slate-700/30'
                  }`}
                >
                  <input
                    type="checkbox"
                    checked={selected.has(src.id)}
                    onChange={() => toggle(src.id)}
                    className="accent-emerald-500"
                  />
                  <span className="text-lg">{src.icon}</span>
                  <div className="flex-1 min-w-0">
                    <div className={`text-sm font-medium ${selected.has(src.id) ? 'text-slate-200' : 'text-slate-500'}`}>
                      {src.label}
                    </div>
                    <div className="text-xs text-slate-600 font-mono truncate">{src.path}</div>
                  </div>
                </label>
              ))}
            </div>
            {selected.size === 0 && (
              <p className="text-xs text-amber-400 mt-2">Select at least one source.</p>
            )}
          </div>

          {/* Constraints */}
          <div>
            <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">Constraints</label>
            <div className="space-y-4">
              <div>
                <div className="flex justify-between text-xs text-slate-400 mb-1">
                  <span>Budget Cap</span>
                  <span className="text-cyan-400 font-mono">PKR {budget.toLocaleString()}</span>
                </div>
                <input type="range" min={100000} max={2000000} step={50000} value={budget}
                  onChange={e => setBudget(Number(e.target.value))}
                  className="w-full accent-cyan-500" />
              </div>
              <div>
                <div className="flex justify-between text-xs text-slate-400 mb-1">
                  <span>Time to Resolution</span>
                  <span className="text-cyan-400 font-mono">{timeRes} hrs</span>
                </div>
                <input type="range" min={2} max={168} step={2} value={timeRes}
                  onChange={e => setTimeRes(Number(e.target.value))}
                  className="w-full accent-cyan-500" />
              </div>
              <div>
                <div className="flex justify-between text-xs text-slate-400 mb-1">
                  <span>API Rate Limit</span>
                  <span className="text-cyan-400 font-mono">{rateLimit}/min</span>
                </div>
                <input type="range" min={1} max={60} step={1} value={rateLimit}
                  onChange={e => setRateLimit(Number(e.target.value))}
                  className="w-full accent-cyan-500" />
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-slate-800 flex items-center justify-between">
          <span className="text-xs text-slate-500">{selected.size} source{selected.size !== 1 ? 's' : ''} selected</span>
          <div className="flex space-x-3">
            <button onClick={onClose} className="px-4 py-2 text-sm text-slate-400 hover:text-slate-200 transition-colors">
              Cancel
            </button>
            <button
              onClick={handleStart}
              disabled={loading || selected.size === 0}
              className="flex items-center space-x-2 px-5 py-2 bg-emerald-500 hover:bg-emerald-400 disabled:opacity-50 text-slate-950 font-semibold text-sm rounded-lg transition-all shadow-[0_0_15px_rgba(16,185,129,0.3)]"
            >
              <Play className="w-4 h-4" />
              <span>{loading ? 'Starting…' : 'Start Run'}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function App() {
  const [runs, setRuns] = useState([]);
  const [selectedRun, setSelectedRun] = useState(null);
  const [showConfig, setShowConfig] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchRuns();
    const interval = setInterval(fetchRuns, 5000);
    return () => clearInterval(interval);
  }, []);

  const fetchRuns = async () => {
    try {
      const data = await getRuns();
      setRuns(data.runs || []);
    } catch (err) {
      console.error('Failed to fetch runs:', err);
    }
  };

  const handleStartRun = async (payload) => {
    setError('');
    try {
      const res = await startRun(payload);
      setSelectedRun(res.run_id);
      setShowConfig(false);
      fetchRuns();
    } catch (err) {
      setError(err.message || 'Failed to start run');
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 text-slate-200">
      {showConfig && (
        <ConfigModal onClose={() => setShowConfig(false)} onStart={handleStartRun} />
      )}

      <header className="border-b border-slate-800 bg-slate-900/50 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 rounded-lg bg-emerald-500/20 flex items-center justify-center border border-emerald-500/30">
              <Activity className="w-5 h-5 text-emerald-400" />
            </div>
            <h1 className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-emerald-400 to-blue-400">
              SENTINEL
            </h1>
            <span className="text-xs font-medium px-2 py-1 rounded-full bg-slate-800 text-slate-400 border border-slate-700">
              Web Dashboard
            </span>
          </div>

          <button
            onClick={() => setShowConfig(true)}
            className="flex items-center space-x-2 px-4 py-2 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-semibold rounded-lg transition-all shadow-[0_0_15px_rgba(16,185,129,0.3)]"
          >
            <Play className="w-4 h-4" />
            <span>New Analysis Run</span>
          </button>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        {error && (
          <div className="mb-6 p-4 rounded-lg bg-red-500/10 border border-red-500/30 text-red-400 flex items-center justify-between">
            <span>{error}</span>
            <button onClick={() => setError('')}><X className="w-4 h-4" /></button>
          </div>
        )}

        <div className="grid grid-cols-12 gap-6">
          {/* Sidebar */}
          <div className="col-span-12 lg:col-span-3 space-y-4">
            <h2 className="text-lg font-semibold text-slate-100 flex items-center space-x-2">
              <Clock className="w-5 h-5 text-blue-400" />
              <span>Recent Runs</span>
            </h2>

            <div className="space-y-3">
              {runs.map((run) => (
                <button
                  key={run.run_id}
                  onClick={() => setSelectedRun(run.run_id)}
                  className={`w-full text-left p-4 rounded-xl border transition-all duration-200 ${
                    selectedRun === run.run_id
                      ? 'bg-blue-500/10 border-blue-500/50 shadow-[0_0_15px_rgba(59,130,246,0.1)]'
                      : 'bg-slate-800/40 border-slate-700/50 hover:bg-slate-800/80 hover:border-slate-600'
                  }`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-mono text-slate-400">
                      {run.run_id.split('_').slice(-1)}
                    </span>
                    {run.status === 'completed' ? (
                      <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                    ) : run.status === 'failed' ? (
                      <XCircle className="w-4 h-4 text-red-400" />
                    ) : (
                      <div className="w-4 h-4 rounded-full border-2 border-blue-400 border-t-transparent animate-spin" />
                    )}
                  </div>
                  <div className="font-medium text-slate-200 capitalize">
                    {run.scenario.replace(/_/g, ' ')}
                  </div>
                  <div className="text-xs text-slate-500 mt-1">
                    {new Date(run.started_at).toLocaleString()}
                  </div>
                </button>
              ))}

              {runs.length === 0 && (
                <div className="text-center p-8 rounded-xl border border-dashed border-slate-700 text-slate-500">
                  No recent runs found.
                </div>
              )}
            </div>
          </div>

          {/* Main Content */}
          <div className="col-span-12 lg:col-span-9">
            {selectedRun ? (
              <RunDetail runId={selectedRun} />
            ) : (
              <div className="h-[600px] rounded-2xl border border-slate-800 bg-slate-800/20 flex flex-col items-center justify-center text-slate-500">
                <Activity className="w-16 h-16 mb-4 text-slate-700" />
                <p className="text-lg">Select a run from the sidebar</p>
                <p className="text-sm mt-1">or start a new analysis</p>
                <button
                  onClick={() => setShowConfig(true)}
                  className="mt-6 flex items-center space-x-2 px-5 py-2.5 bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/30 text-emerald-400 rounded-lg transition-all text-sm font-medium"
                >
                  <Play className="w-4 h-4" />
                  <span>Start your first run</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}

export default App;
