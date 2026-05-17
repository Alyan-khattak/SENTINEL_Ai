import { CheckCircle2, Circle, AlertCircle, RefreshCw } from 'lucide-react';

export default function TraceTimeline({ events, report }) {
  // If run is completed, we can also derive timeline from report execution_log
  // but events give us the live stream.
  
  const timelineEvents = events.map((e, idx) => {
    let icon = <Circle className="w-4 h-4 text-slate-500" />;
    let color = "text-slate-400";
    let title = e.event.replace(/_/g, ' ');
    if (e.data && e.data.action_name) {
      const actionName = e.data.action_name.replace(/_/g, ' ');
      title = `${actionName} (${title})`;
    }
    let detail = "";

    if (e.event.endsWith('_done') || e.event === 'run_completed') {
      icon = <CheckCircle2 className="w-4 h-4 text-emerald-400" />;
      color = "text-emerald-400";
    } else if (e.event === 'step_failed' || e.event === 'run_failed') {
      icon = <AlertCircle className="w-4 h-4 text-red-400" />;
      color = "text-red-400";
      detail = e.data.error || "Execution failed";
    } else if (e.event === 'step_retrying') {
      icon = <RefreshCw className="w-4 h-4 text-amber-400 animate-spin" />;
      color = "text-amber-400";
    }

    if (e.event === 'planner_done') {
      detail = `Generated ${e.data.task_plan?.steps?.length || 0} steps`;
    } else if (e.event === 'noise_filter_done') {
      detail = `Kept ${e.data.kept?.length || 0}, Rejected ${e.data.rejected?.length || 0}`;
    } else if (e.event === 'conflict_done') {
      const confs = e.data.conflict_resolution?.contradictions?.length || 0;
      detail = confs > 0 ? `Resolved ${confs} contradictions` : "No conflicts detected";
      if (confs > 0) color = "text-amber-400";
    } else if (e.event === 'action_planner_done') {
      detail = `Planned ${e.data.action_count} actions`;
    }

    return { id: idx, title, detail, color, icon, time: new Date(e.timestamp).toLocaleTimeString() };
  });

  if (timelineEvents.length === 0 && report) {
    // fallback to static view if no events but report exists
    timelineEvents.push({
      id: 'static',
      title: 'Run Completed',
      detail: 'View baseline comparison for details',
      color: 'text-emerald-400',
      icon: <CheckCircle2 className="w-4 h-4 text-emerald-400" />,
      time: new Date(report.completed_at).toLocaleTimeString()
    });
  }

  return (
    <div className="space-y-4 relative before:absolute before:inset-0 before:ml-2 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-slate-700 before:to-transparent">
      {timelineEvents.map((item) => (
        <div key={item.id} className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group is-active">
          <div className="flex items-center justify-center w-5 h-5 rounded-full border border-slate-700 bg-slate-800 text-slate-500 shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 z-10">
            {item.icon}
          </div>
          <div className="w-[calc(100%-2.5rem)] md:w-[calc(50%-1.5rem)] p-3 rounded-lg border border-slate-700/50 bg-slate-800/40 shadow-sm transition-all hover:bg-slate-800/80">
            <div className="flex items-center justify-between space-x-2 mb-1">
              <div className={`font-semibold capitalize text-sm ${item.color}`}>{item.title}</div>
              <time className="font-mono text-xs text-slate-500">{item.time}</time>
            </div>
            {item.detail && <div className="text-xs text-slate-400">{item.detail}</div>}
          </div>
        </div>
      ))}
    </div>
  );
}
