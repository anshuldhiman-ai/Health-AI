import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { api } from "../api/client.js";
import TradeChart from "../components/TradeChart.jsx";
import { computePnl, formatINR } from "../lib/calc.js";

function Field({ label, children }) {
  return (
    <div>
      <div className="text-xs uppercase tracking-wide text-neutral-500">{label}</div>
      <div className="mt-1 text-sm text-neutral-100">{children}</div>
    </div>
  );
}

export default function TradeDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [trade, setTrade] = useState(null);
  const [draft, setDraft] = useState(null);
  const [editing, setEditing] = useState(false);
  const [err, setErr] = useState(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    api
      .getTrade(id)
      .then((t) => {
        setTrade(t);
        setDraft(t);
      })
      .catch((e) => setErr(String(e.message || e)));
  }, [id]);

  if (err) return <div className="text-loss">{err}</div>;
  if (!trade || !draft) return <div className="text-neutral-400">Loading…</div>;

  const isOpen = trade.sellPrice === null || trade.sellPrice === undefined;
  const livePnl = computePnl(draft);
  const upd = (patch) => setDraft((d) => ({ ...d, ...patch }));

  const save = async () => {
    setSaving(true);
    try {
      const updated = await api.updateTrade(trade.id, draft);
      setTrade(updated);
      setDraft(updated);
      setEditing(false);
    } catch (e) {
      setErr(String(e.message || e));
    } finally {
      setSaving(false);
    }
  };

  const remove = async () => {
    if (!confirm("Delete this trade?")) return;
    await api.deleteTrade(trade.id);
    navigate("/journal");
  };

  return (
    <div className="space-y-6">
      <div className="flex items-baseline justify-between">
        <div>
          <Link to="/journal" className="text-sm text-neutral-500 hover:text-white">
            ← Back to journal
          </Link>
          <h2 className="text-xl font-semibold mt-1">
            {trade.stock}{" "}
            <span className="text-neutral-500 text-base font-normal">
              · {trade.exchange} · {trade.segment}
            </span>
          </h2>
        </div>
        <div className="flex items-center gap-3">
          <span
            className={`text-lg font-semibold ${
              isOpen ? "text-neutral-500" : livePnl > 0 ? "text-gain" : livePnl < 0 ? "text-loss" : "text-neutral-300"
            }`}
          >
            {isOpen ? "Open position" : formatINR(livePnl)}
          </span>
          {editing ? (
            <>
              <button
                onClick={() => {
                  setDraft(trade);
                  setEditing(false);
                }}
                className="text-sm text-neutral-400 hover:text-white"
              >
                Cancel
              </button>
              <button
                onClick={save}
                disabled={saving}
                className="text-sm bg-gain text-white rounded px-3 py-1.5 disabled:opacity-50"
              >
                {saving ? "Saving…" : "Save"}
              </button>
            </>
          ) : (
            <>
              <button
                onClick={() => setEditing(true)}
                className="text-sm text-neutral-300 hover:text-white"
              >
                Edit
              </button>
              <button onClick={remove} className="text-sm text-neutral-500 hover:text-loss">
                Delete
              </button>
            </>
          )}
        </div>
      </div>

      <TradeChart
        symbol={trade.stock}
        exchange={trade.exchange}
        entryDate={trade.date}
        entryPrice={trade.buyPrice}
        exitDate={isOpen ? null : trade.date}
        exitPrice={isOpen ? null : trade.sellPrice}
        height={420}
      />

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 rounded-lg border border-neutral-800 bg-neutral-900 p-4">
        <Field label="Date">
          {editing ? (
            <input
              type="date"
              value={draft.date.slice(0, 10)}
              onChange={(e) => upd({ date: e.target.value })}
              className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-36"
            />
          ) : (
            new Date(trade.date).toLocaleDateString("en-IN")
          )}
        </Field>

        <Field label="Direction">
          {editing ? (
            <select
              value={draft.direction}
              onChange={(e) => upd({ direction: e.target.value })}
              className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm"
            >
              <option>Long</option>
              <option>Short</option>
            </select>
          ) : (
            trade.direction
          )}
        </Field>

        <Field label="Buy price">₹{Number(trade.buyPrice).toFixed(2)}</Field>

        <Field label="Sell price">
          {editing ? (
            <input
              type="number"
              step="0.01"
              value={draft.sellPrice ?? ""}
              placeholder="open"
              onChange={(e) => upd({ sellPrice: e.target.value === "" ? null : e.target.value })}
              className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-28"
            />
          ) : isOpen ? (
            <span className="text-neutral-500">open</span>
          ) : (
            `₹${Number(trade.sellPrice).toFixed(2)}`
          )}
        </Field>

        <Field label="Quantity">{trade.lotSize * trade.lots}</Field>

        <Field label="Lot size × Lots">
          {editing ? (
            <div className="flex gap-1">
              <input
                type="number"
                value={draft.lotSize}
                onChange={(e) => upd({ lotSize: Number(e.target.value) })}
                className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-16"
              />
              <input
                type="number"
                step="0.01"
                value={draft.lots}
                onChange={(e) => upd({ lots: e.target.value })}
                className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-20"
              />
            </div>
          ) : (
            `${trade.lotSize} × ${trade.lots}`
          )}
        </Field>

        <Field label="Charges">
          {editing ? (
            <input
              type="number"
              step="0.01"
              value={draft.charges}
              onChange={(e) => upd({ charges: Number(e.target.value) })}
              className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-28"
            />
          ) : (
            formatINR(trade.charges)
          )}
        </Field>

        <Field label="Source">{trade.source}</Field>

        <div className="col-span-2">
          <div className="text-xs uppercase tracking-wide text-neutral-500">Strategy</div>
          {editing ? (
            <input
              value={draft.strategy ?? ""}
              onChange={(e) => upd({ strategy: e.target.value })}
              className="mt-1 bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-full"
              placeholder="e.g. breakout, mean reversion"
            />
          ) : (
            <div className="mt-1 text-sm text-neutral-100">{trade.strategy || "—"}</div>
          )}
        </div>

        <div className="col-span-2">
          <div className="text-xs uppercase tracking-wide text-neutral-500">Notes</div>
          {editing ? (
            <textarea
              value={draft.notes ?? ""}
              onChange={(e) => upd({ notes: e.target.value })}
              className="mt-1 bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-full h-20 resize-y"
              placeholder="What did you see? What worked?"
            />
          ) : (
            <div className="mt-1 text-sm text-neutral-100 whitespace-pre-wrap">
              {trade.notes || "—"}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
