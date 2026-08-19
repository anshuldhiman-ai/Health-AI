import { formatINRShort } from "../lib/calc.js";

// Single tile for the dashboard. Tone = "neutral" | "gain" | "loss".
// Green is reserved for actual gains per CLAUDE.md.
export default function StatCard({ label, value, tone = "neutral", sub }) {
  const valueClass =
    tone === "gain" ? "text-gain" : tone === "loss" ? "text-loss" : "text-white";
  return (
    <div className="rounded-lg border border-neutral-800 bg-neutral-900 p-4">
      <div className="text-xs uppercase tracking-wide text-neutral-500">{label}</div>
      <div className={`mt-1 text-2xl font-semibold ${valueClass}`}>{value}</div>
      {sub ? <div className="mt-1 text-xs text-neutral-500">{sub}</div> : null}
    </div>
  );
}

// Convenience wrapper for money stats that derive their tone from sign.
export function MoneyStat({ label, value, sub }) {
  const tone = value > 0 ? "gain" : value < 0 ? "loss" : "neutral";
  return <StatCard label={label} value={formatINRShort(value)} sub={sub} tone={tone} />;
}
