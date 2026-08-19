import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client.js";
import StatCard, { MoneyStat } from "../components/StatCard.jsx";
import { formatINR, formatINRShort } from "../lib/calc.js";
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from "recharts";

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [recent, setRecent] = useState([]);
  const [err, setErr] = useState(null);

  useEffect(() => {
    Promise.all([api.dashboardStats(), api.listTrades()])
      .then(([s, t]) => {
        setStats(s);
        setRecent(t.slice(0, 8));
      })
      .catch((e) => setErr(String(e.message || e)));
  }, []);

  if (err) return <div className="text-loss">Failed to load: {err}</div>;
  if (!stats) return <div className="text-neutral-400">Loading…</div>;

  const empty = stats.totalTrades === 0;

  return (
    <div className="space-y-6">
      {empty ? (
        <div className="rounded-lg border border-dashed border-neutral-700 bg-neutral-900 p-8 text-center">
          <div className="text-neutral-300 mb-1">No trades yet.</div>
          <Link to="/journal" className="text-sm text-white underline">
            Add your first trade →
          </Link>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <MoneyStat label="Net P&L" value={stats.netPnl} />
            <StatCard
              label="Win rate"
              value={`${(stats.winRate * 100).toFixed(1)}%`}
              sub={`${stats.wins}W · ${stats.losses}L`}
            />
            <StatCard
              label="Open positions"
              value={stats.openCount}
              sub={`${stats.closedCount} closed`}
            />
            <MoneyStat label="Charges paid" value={-stats.charges} sub="brokerage + taxes" />
          </div>

          <div className="rounded-lg border border-neutral-800 bg-neutral-900 p-4">
            <div className="flex items-baseline justify-between mb-2">
              <div className="text-sm text-neutral-400">Equity curve</div>
              <div className="text-xs text-neutral-500">{stats.equityCurve.length} closed trades</div>
            </div>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={stats.equityCurve}>
                  <CartesianGrid stroke="#1f2937" />
                  <XAxis
                    dataKey="date"
                    tickFormatter={(d) => new Date(d).toLocaleDateString("en-IN", { month: "short", day: "2-digit" })}
                    tick={{ fill: "#9ca3af", fontSize: 12 }}
                  />
                  <YAxis
                    tickFormatter={(v) => formatINRShort(v)}
                    tick={{ fill: "#9ca3af", fontSize: 12 }}
                  />
                  <Tooltip
                    contentStyle={{ background: "#111827", border: "1px solid #1f2937" }}
                    labelFormatter={(d) => new Date(d).toLocaleDateString("en-IN")}
                    formatter={(v) => [formatINR(v), "Equity"]}
                  />
                  <Line
                    type="monotone"
                    dataKey="equity"
                    stroke="#16a34a"
                    strokeWidth={2}
                    dot={false}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="rounded-lg border border-neutral-800 bg-neutral-900">
            <div className="px-4 py-3 border-b border-neutral-800 text-sm text-neutral-400">
              Recent trades
            </div>
            <table className="w-full text-sm">
              <thead className="text-neutral-500">
                <tr>
                  <th className="text-left px-4 py-2">Date</th>
                  <th className="text-left px-4 py-2">Symbol</th>
                  <th className="text-left px-4 py-2">Segment</th>
                  <th className="text-right px-4 py-2">Qty</th>
                  <th className="text-right px-4 py-2">P&L</th>
                </tr>
              </thead>
              <tbody>
                {recent.map((t) => (
                  <tr key={t.id} className="border-t border-neutral-800 hover:bg-neutral-800/50">
                    <td className="px-4 py-2 text-neutral-300">
                      {new Date(t.date).toLocaleDateString("en-IN")}
                    </td>
                    <td className="px-4 py-2 font-medium">
                      <Link to={`/trade/${t.id}`} className="hover:underline">
                        {t.stock}
                      </Link>
                    </td>
                    <td className="px-4 py-2 text-neutral-400">{t.segment}</td>
                    <td className="px-4 py-2 text-right text-neutral-300">
                      {t.lotSize * t.lots}
                    </td>
                    <td
                      className={`px-4 py-2 text-right ${
                        t.pnl === null
                          ? "text-neutral-500"
                          : t.pnl > 0
                          ? "text-gain"
                          : t.pnl < 0
                          ? "text-loss"
                          : "text-neutral-300"
                      }`}
                    >
                      {t.pnl === null ? "open" : formatINR(t.pnl)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  );
}
