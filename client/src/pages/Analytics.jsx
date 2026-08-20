import { useEffect, useMemo, useState } from "react";
import { api } from "../api/client.js";
import { formatINR, formatINRShort } from "../lib/calc.js";
import {
  BarChart,
  Bar,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  Cell,
} from "recharts";

// Group closed trades by YYYY-MM and sum pnl. Sorts ascending.
function monthlyPnl(trades) {
  const buckets = new Map();
  for (const t of trades) {
    if (t.pnl === null || t.pnl === undefined) continue;
    const key = t.date.slice(0, 7); // YYYY-MM
    buckets.set(key, (buckets.get(key) || 0) + t.pnl);
  }
  return Array.from(buckets.entries())
    .sort(([a], [b]) => (a < b ? -1 : 1))
    .map(([month, pnl]) => ({ month, pnl }));
}

// Group trades by a key (strategy/segment/symbol), summing pnl and counting wins/losses.
function groupBy(trades, keyFn) {
  const out = new Map();
  for (const t of trades) {
    if (t.pnl === null || t.pnl === undefined) continue;
    const k = keyFn(t) || "(unspecified)";
    const cur = out.get(k) || { name: k, pnl: 0, wins: 0, losses: 0, trades: 0 };
    cur.pnl += t.pnl;
    cur.trades += 1;
    if (t.pnl > 0) cur.wins += 1;
    else if (t.pnl < 0) cur.losses += 1;
    out.set(k, cur);
  }
  return Array.from(out.values()).sort((a, b) => b.pnl - a.pnl);
}

// Longest streaks of consecutive wins / losses across sorted closed trades.
function streaks(trades) {
  const sorted = [...trades]
    .filter((t) => t.pnl !== null && t.pnl !== undefined)
    .sort((a, b) => new Date(a.date) - new Date(b.date));
  let bestW = 0, bestL = 0;
  let curW = 0, curL = 0;
  let lastSign = 0;
  for (const t of sorted) {
    const sign = t.pnl > 0 ? 1 : t.pnl < 0 ? -1 : 0;
    if (sign === 0) continue;
    if (sign === lastSign) {
      if (sign > 0) curW++;
      else curL++;
    } else {
      curW = sign > 0 ? 1 : 0;
      curL = sign < 0 ? 1 : 0;
      lastSign = sign;
    }
    if (curW > bestW) bestW = curW;
    if (curL > bestL) bestL = curL;
  }
  return { bestW, bestL, current: curW - curL };
}

export default function Analytics() {
  const [trades, setTrades] = useState([]);
  const [err, setErr] = useState(null);

  useEffect(() => {
    api.listTrades().then(setTrades).catch((e) => setErr(String(e.message || e)));
  }, []);

  const monthly = useMemo(() => monthlyPnl(trades), [trades]);
  const byStrategy = useMemo(() => groupBy(trades, (t) => t.strategy), [trades]);
  const bySegment = useMemo(() => groupBy(trades, (t) => t.segment), [trades]);
  const bySymbol = useMemo(() => groupBy(trades, (t) => t.stock).slice(0, 10), [trades]);
  const { bestW, bestL, current } = useMemo(() => streaks(trades), [trades]);

  if (err) return <div className="text-loss">{err}</div>;
  if (trades.length === 0) {
    return (
      <div className="rounded-lg border border-dashed border-neutral-700 bg-neutral-900 p-8 text-center text-neutral-400">
        No trades yet — analytics will appear once you log some.
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-medium">Analytics</h2>

      {/* Streaks */}
      <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
        <Stat label="Longest win streak" value={bestW} tone="gain" />
        <Stat label="Longest loss streak" value={bestL} tone="loss" />
        <Stat
          label="Current streak"
          value={current > 0 ? `${current}W` : current < 0 ? `${Math.abs(current)}L` : "—"}
          tone={current > 0 ? "gain" : current < 0 ? "loss" : "neutral"}
        />
      </div>

      {/* Monthly P&L bar chart */}
      <div className="rounded-lg border border-neutral-800 bg-neutral-900 p-4">
        <div className="text-sm text-neutral-400 mb-2">Monthly P&L</div>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={monthly}>
              <CartesianGrid stroke="#1f2937" vertical={false} />
              <XAxis dataKey="month" tick={{ fill: "#9ca3af", fontSize: 12 }} />
              <YAxis tickFormatter={(v) => formatINRShort(v)} tick={{ fill: "#9ca3af", fontSize: 12 }} />
              <Tooltip
                contentStyle={{ background: "#111827", border: "1px solid #1f2937" }}
                formatter={(v) => [formatINR(v), "P&L"]}
                cursor={{ fill: "#1f2937" }}
              />
              <Bar dataKey="pnl">
                {monthly.map((m, i) => (
                  <Cell key={i} fill={m.pnl >= 0 ? "#16a34a" : "#dc2626"} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Strategy + segment breakdowns side-by-side */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <BreakdownTable title="By strategy" rows={byStrategy} />
        <BreakdownTable title="By segment" rows={bySegment} />
      </div>

      {/* Top symbols */}
      <div className="rounded-lg border border-neutral-800 bg-neutral-900">
        <div className="px-4 py-3 border-b border-neutral-800 text-sm text-neutral-400">
          Top symbols by P&L
        </div>
        <BreakdownTable rows={bySymbol} compact />
      </div>
    </div>
  );
}

function Stat({ label, value, tone }) {
  const cls =
    tone === "gain" ? "text-gain" : tone === "loss" ? "text-loss" : "text-white";
  return (
    <div className="rounded-lg border border-neutral-800 bg-neutral-900 p-4">
      <div className="text-xs uppercase tracking-wide text-neutral-500">{label}</div>
      <div className={`mt-1 text-2xl font-semibold ${cls}`}>{value}</div>
    </div>
  );
}

function BreakdownTable({ title, rows, compact = false }) {
  if (compact) {
    return (
      <table className="w-full text-sm">
        <thead className="text-neutral-500">
          <tr>
            <th className="text-left px-4 py-2">Symbol</th>
            <th className="text-right px-4 py-2">Trades</th>
            <th className="text-right px-4 py-2">Win%</th>
            <th className="text-right px-4 py-2">P&L</th>
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 ? (
            <tr>
              <td colSpan={4} className="px-4 py-6 text-center text-neutral-500">
                No closed trades.
              </td>
            </tr>
          ) : (
            rows.map((r) => {
              const winRate = r.trades ? r.wins / r.trades : 0;
              return (
                <tr key={r.name} className="border-t border-neutral-800">
                  <td className="px-4 py-2">{r.name}</td>
                  <td className="px-4 py-2 text-right text-neutral-300">{r.trades}</td>
                  <td className="px-4 py-2 text-right text-neutral-300">
                    {(winRate * 100).toFixed(0)}%
                  </td>
                  <td
                    className={`px-4 py-2 text-right ${
                      r.pnl > 0 ? "text-gain" : r.pnl < 0 ? "text-loss" : "text-neutral-300"
                    }`}
                  >
                    {formatINR(r.pnl)}
                  </td>
                </tr>
              );
            })
          )}
        </tbody>
      </table>
    );
  }
  return (
    <div className="rounded-lg border border-neutral-800 bg-neutral-900">
      <div className="px-4 py-3 border-b border-neutral-800 text-sm text-neutral-400">
        {title}
      </div>
      <table className="w-full text-sm">
        <thead className="text-neutral-500">
          <tr>
            <th className="text-left px-4 py-2">Name</th>
            <th className="text-right px-4 py-2">Trades</th>
            <th className="text-right px-4 py-2">W/L</th>
            <th className="text-right px-4 py-2">P&L</th>
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 ? (
            <tr>
              <td colSpan={4} className="px-4 py-6 text-center text-neutral-500">
                No closed trades yet.
              </td>
            </tr>
          ) : (
            rows.map((r) => (
              <tr key={r.name} className="border-t border-neutral-800">
                <td className="px-4 py-2">{r.name}</td>
                <td className="px-4 py-2 text-right text-neutral-300">{r.trades}</td>
                <td className="px-4 py-2 text-right text-neutral-300">
                  <span className="text-gain">{r.wins}</span>
                  <span className="text-neutral-600"> / </span>
                  <span className="text-loss">{r.losses}</span>
                </td>
                <td
                  className={`px-4 py-2 text-right ${
                    r.pnl > 0 ? "text-gain" : r.pnl < 0 ? "text-loss" : "text-neutral-300"
                  }`}
                >
                  {formatINR(r.pnl)}
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}
