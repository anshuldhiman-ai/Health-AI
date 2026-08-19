import { useMemo, useState } from "react";
import { computePnl, formatINR } from "../lib/calc.js";

// Editable preview table. User can fix a misparsed row before commit.
// Rows that look broken are highlighted (red dot in left column).

function isRowBroken(r) {
  return (
    !r.stock ||
    !Number.isFinite(Number(r.buyPrice)) ||
    Number(r.buyPrice) <= 0 ||
    !Number.isFinite(Number(r.lots)) ||
    Number(r.lots) <= 0
  );
}

export default function UploadPreviewTable({ rows, setRows, onCommit, onCancel }) {
  const [filter, setFilter] = useState("");

  const visible = useMemo(() => {
    if (!filter) return rows.map((r, i) => ({ r, i }));
    const q = filter.toUpperCase();
    return rows.map((r, i) => ({ r, i })).filter(({ r }) => r.stock?.toUpperCase().includes(q));
  }, [rows, filter]);

  const update = (idx, patch) => {
    setRows((rs) => rs.map((r, i) => (i === idx ? { ...r, ...patch } : r)));
  };
  const remove = (idx) => setRows((rs) => rs.filter((_, i) => i !== idx));

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <input
          placeholder="Filter…"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="bg-neutral-900 border border-neutral-700 rounded px-3 py-1.5 text-sm w-48"
        />
        <span className="text-xs text-neutral-500">{rows.length} rows</span>
        <div className="ml-auto flex gap-2">
          <button onClick={onCancel} className="px-3 py-1.5 text-sm text-neutral-400 hover:text-white">
            Cancel
          </button>
          <button
            onClick={onCommit}
            className="px-3 py-1.5 text-sm bg-white text-black rounded"
          >
            Commit {rows.length} trades
          </button>
        </div>
      </div>

      <div className="rounded-lg border border-neutral-800 bg-neutral-900 overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="text-neutral-500 bg-neutral-950">
            <tr>
              <th className="px-2 py-2 w-2" />
              <th className="text-left px-2 py-2 font-medium">Date</th>
              <th className="text-left px-2 py-2 font-medium">Symbol</th>
              <th className="text-left px-2 py-2 font-medium">Exch</th>
              <th className="text-left px-2 py-2 font-medium">Seg</th>
              <th className="text-left px-2 py-2 font-medium">Dir</th>
              <th className="text-right px-2 py-2 font-medium">Buy</th>
              <th className="text-right px-2 py-2 font-medium">Sell</th>
              <th className="text-right px-2 py-2 font-medium">Lots</th>
              <th className="text-right px-2 py-2 font-medium">LotSz</th>
              <th className="text-right px-2 py-2 font-medium">Charges</th>
              <th className="text-right px-2 py-2 font-medium">P&L</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {visible.map(({ r, i }) => {
              const broken = isRowBroken(r);
              const pnl = computePnl(r);
              return (
                <tr key={i} className={`border-t border-neutral-800 ${broken ? "bg-loss/5" : ""}`}>
                  <td className="px-2 py-1.5">
                    {broken ? <span className="block h-2 w-2 rounded-full bg-loss" title="incomplete" /> : null}
                  </td>
                  <td className="px-2 py-1.5">
                    <input
                      type="date"
                      value={r.date ? r.date.slice(0, 10) : ""}
                      onChange={(e) => update(i, { date: e.target.value })}
                      className="bg-neutral-800 border border-neutral-700 rounded px-1.5 py-0.5 text-xs w-32"
                    />
                  </td>
                  <td className="px-2 py-1.5">
                    <input
                      value={r.stock}
                      onChange={(e) => update(i, { stock: e.target.value.toUpperCase() })}
                      className="bg-neutral-800 border border-neutral-700 rounded px-1.5 py-0.5 text-xs w-24"
                    />
                  </td>
                  <td className="px-2 py-1.5">
                    <select
                      value={r.exchange}
                      onChange={(e) => update(i, { exchange: e.target.value })}
                      className="bg-neutral-800 border border-neutral-700 rounded px-1.5 py-0.5 text-xs"
                    >
                      <option>NSE</option>
                      <option>BSE</option>
                    </select>
                  </td>
                  <td className="px-2 py-1.5">
                    <select
                      value={r.segment}
                      onChange={(e) => update(i, { segment: e.target.value })}
                      className="bg-neutral-800 border border-neutral-700 rounded px-1.5 py-0.5 text-xs"
                    >
                      <option>Equity</option>
                      <option>Futures</option>
                      <option>Options</option>
                    </select>
                  </td>
                  <td className="px-2 py-1.5">
                    <select
                      value={r.direction}
                      onChange={(e) => update(i, { direction: e.target.value })}
                      className="bg-neutral-800 border border-neutral-700 rounded px-1.5 py-0.5 text-xs"
                    >
                      <option>Long</option>
                      <option>Short</option>
                    </select>
                  </td>
                  <td className="px-2 py-1.5 text-right">
                    <input
                      type="number"
                      step="0.01"
                      value={r.buyPrice}
                      onChange={(e) => update(i, { buyPrice: e.target.value })}
                      className="bg-neutral-800 border border-neutral-700 rounded px-1.5 py-0.5 text-xs w-20 text-right"
                    />
                  </td>
                  <td className="px-2 py-1.5 text-right">
                    <input
                      type="number"
                      step="0.01"
                      placeholder="open"
                      value={r.sellPrice ?? ""}
                      onChange={(e) =>
                        update(i, { sellPrice: e.target.value === "" ? null : e.target.value })
                      }
                      className="bg-neutral-800 border border-neutral-700 rounded px-1.5 py-0.5 text-xs w-20 text-right"
                    />
                  </td>
                  <td className="px-2 py-1.5 text-right">
                    <input
                      type="number"
                      step="0.01"
                      value={r.lots}
                      onChange={(e) => update(i, { lots: e.target.value })}
                      className="bg-neutral-800 border border-neutral-700 rounded px-1.5 py-0.5 text-xs w-16 text-right"
                    />
                  </td>
                  <td className="px-2 py-1.5 text-right">
                    <input
                      type="number"
                      value={r.lotSize}
                      onChange={(e) => update(i, { lotSize: Number(e.target.value) })}
                      className="bg-neutral-800 border border-neutral-700 rounded px-1.5 py-0.5 text-xs w-14 text-right"
                    />
                  </td>
                  <td className="px-2 py-1.5 text-right">
                    <input
                      type="number"
                      step="0.01"
                      value={r.charges}
                      onChange={(e) => update(i, { charges: e.target.value })}
                      className="bg-neutral-800 border border-neutral-700 rounded px-1.5 py-0.5 text-xs w-16 text-right"
                    />
                  </td>
                  <td
                    className={`px-2 py-1.5 text-right text-xs ${
                      pnl === null ? "text-neutral-500" : pnl > 0 ? "text-gain" : pnl < 0 ? "text-loss" : "text-neutral-300"
                    }`}
                  >
                    {pnl === null ? "open" : formatINR(pnl)}
                  </td>
                  <td className="px-2 py-1.5 text-right">
                    <button
                      onClick={() => remove(i)}
                      className="text-xs text-neutral-500 hover:text-loss"
                    >
                      ×
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
