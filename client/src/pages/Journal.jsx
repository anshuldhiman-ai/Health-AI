import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client.js";
import { formatINR, computePnl } from "../lib/calc.js";

const EMPTY = {
  date: new Date().toISOString().slice(0, 10),
  stock: "",
  exchange: "NSE",
  segment: "Equity",
  direction: "Long",
  buyPrice: "",
  sellPrice: "",
  lotSize: 1,
  lots: "",
  charges: 0,
  notes: "",
  strategy: "",
};

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

function TradeRow({ trade, onSave, onDelete }) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(trade);

  // Re-sync if upstream trade changes (e.g. after a save).
  useEffect(() => setDraft(trade), [trade]);

  const livePnl = computePnl(draft);

  if (!editing) {
    const open = trade.sellPrice === null || trade.sellPrice === undefined;
    return (
      <tr className="border-t border-neutral-800 hover:bg-neutral-800/40">
        <td className="px-3 py-2 text-neutral-300">{new Date(trade.date).toLocaleDateString("en-IN")}</td>
        <td className="px-3 py-2">
          <Link to={`/trade/${trade.id}`} className="font-medium hover:underline">
            {trade.stock}
          </Link>
        </td>
        <td className="px-3 py-2 text-neutral-400">{trade.exchange}</td>
        <td className="px-3 py-2 text-neutral-400">{trade.segment}</td>
        <td className="px-3 py-2 text-neutral-400">{trade.direction}</td>
        <td className="px-3 py-2 text-right text-neutral-300">{trade.lotSize * trade.lots}</td>
        <td className="px-3 py-2 text-right text-neutral-300">{Number(trade.buyPrice).toFixed(2)}</td>
        <td className="px-3 py-2 text-right text-neutral-300">
          {open ? <span className="text-neutral-500">open</span> : Number(trade.sellPrice).toFixed(2)}
        </td>
        <td
          className={`px-3 py-2 text-right ${
            open ? "text-neutral-500" : livePnl > 0 ? "text-gain" : livePnl < 0 ? "text-loss" : "text-neutral-300"
          }`}
        >
          {open ? "—" : formatINR(livePnl)}
        </td>
        <td className="px-3 py-2 text-right">
          <button
            onClick={() => setEditing(true)}
            className="text-xs text-neutral-400 hover:text-white mr-2"
          >
            edit
          </button>
          <button
            onClick={() => onDelete(trade.id)}
            className="text-xs text-neutral-500 hover:text-loss"
          >
            delete
          </button>
        </td>
      </tr>
    );
  }

  // Edit mode: inline inputs that match the column widths above.
  const upd = (patch) => setDraft((d) => ({ ...d, ...patch }));
  return (
    <tr className="border-t border-neutral-700 bg-neutral-900">
      <td className="px-3 py-2">
        <input
          type="date"
          value={draft.date ? draft.date.slice(0, 10) : todayISO()}
          onChange={(e) => upd({ date: e.target.value })}
          className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-32"
        />
      </td>
      <td className="px-3 py-2">
        <input
          value={draft.stock}
          onChange={(e) => upd({ stock: e.target.value.toUpperCase() })}
          className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-24"
        />
      </td>
      <td className="px-3 py-2">
        <select
          value={draft.exchange}
          onChange={(e) => upd({ exchange: e.target.value })}
          className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm"
        >
          <option>NSE</option>
          <option>BSE</option>
        </select>
      </td>
      <td className="px-3 py-2">
        <select
          value={draft.segment}
          onChange={(e) => upd({ segment: e.target.value })}
          className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm"
        >
          <option>Equity</option>
          <option>Futures</option>
          <option>Options</option>
        </select>
      </td>
      <td className="px-3 py-2">
        <select
          value={draft.direction}
          onChange={(e) => upd({ direction: e.target.value })}
          className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm"
        >
          <option>Long</option>
          <option>Short</option>
        </select>
      </td>
      <td className="px-3 py-2">
        <div className="flex gap-1 justify-end">
          <input
            type="number"
            value={draft.lotSize}
            onChange={(e) => upd({ lotSize: Number(e.target.value) })}
            className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-14 text-right"
          />
          <input
            type="number"
            step="0.01"
            value={draft.lots}
            onChange={(e) => upd({ lots: e.target.value })}
            className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-16 text-right"
          />
        </div>
      </td>
      <td className="px-3 py-2">
        <input
          type="number"
          step="0.01"
          value={draft.buyPrice}
          onChange={(e) => upd({ buyPrice: e.target.value })}
          className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-20 text-right"
        />
      </td>
      <td className="px-3 py-2">
        <input
          type="number"
          step="0.01"
          value={draft.sellPrice ?? ""}
          placeholder="open"
          onChange={(e) => upd({ sellPrice: e.target.value === "" ? null : e.target.value })}
          className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm w-20 text-right"
        />
      </td>
      <td
        className={`px-3 py-2 text-right text-sm ${
          livePnl === null ? "text-neutral-500" : livePnl > 0 ? "text-gain" : livePnl < 0 ? "text-loss" : "text-neutral-300"
        }`}
      >
        {livePnl === null ? "open" : formatINR(livePnl)}
      </td>
      <td className="px-3 py-2 text-right">
        <button
          onClick={async () => {
            await onSave(draft);
            setEditing(false);
          }}
          className="text-xs text-white bg-gain rounded px-2 py-1 mr-1"
        >
          save
        </button>
        <button
          onClick={() => {
            setDraft(trade);
            setEditing(false);
          }}
          className="text-xs text-neutral-400 hover:text-white"
        >
          cancel
        </button>
      </td>
    </tr>
  );
}

function AddRow({ onCreate }) {
  const [draft, setDraft] = useState(EMPTY);
  const livePnl = computePnl(draft);
  const upd = (patch) => setDraft((d) => ({ ...d, ...patch }));
  const submit = async () => {
    if (!draft.stock || !draft.lots || !draft.buyPrice) return;
    await onCreate(draft);
    setDraft({ ...EMPTY, date: todayISO() });
  };
  return (
    <tr className="border-b border-neutral-700 bg-neutral-950">
      <td className="px-3 py-2">
        <input
          type="date"
          value={draft.date}
          onChange={(e) => upd({ date: e.target.value })}
          className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1 text-sm w-32"
        />
      </td>
      <td className="px-3 py-2">
        <input
          value={draft.stock}
          placeholder="SYMBOL"
          onChange={(e) => upd({ stock: e.target.value.toUpperCase() })}
          className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1 text-sm w-24 placeholder-neutral-600"
        />
      </td>
      <td className="px-3 py-2">
        <select
          value={draft.exchange}
          onChange={(e) => upd({ exchange: e.target.value })}
          className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1 text-sm"
        >
          <option>NSE</option>
          <option>BSE</option>
        </select>
      </td>
      <td className="px-3 py-2">
        <select
          value={draft.segment}
          onChange={(e) => upd({ segment: e.target.value })}
          className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1 text-sm"
        >
          <option>Equity</option>
          <option>Futures</option>
          <option>Options</option>
        </select>
      </td>
      <td className="px-3 py-2">
        <select
          value={draft.direction}
          onChange={(e) => upd({ direction: e.target.value })}
          className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1 text-sm"
        >
          <option>Long</option>
          <option>Short</option>
        </select>
      </td>
      <td className="px-3 py-2">
        <div className="flex gap-1 justify-end">
          <input
            type="number"
            value={draft.lotSize}
            onChange={(e) => upd({ lotSize: Number(e.target.value) })}
            className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1 text-sm w-14 text-right"
          />
          <input
            type="number"
            step="0.01"
            placeholder="lots"
            value={draft.lots}
            onChange={(e) => upd({ lots: e.target.value })}
            className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1 text-sm w-16 text-right placeholder-neutral-600"
          />
        </div>
      </td>
      <td className="px-3 py-2">
        <input
          type="number"
          step="0.01"
          placeholder="buy"
          value={draft.buyPrice}
          onChange={(e) => upd({ buyPrice: e.target.value })}
          className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1 text-sm w-20 text-right placeholder-neutral-600"
        />
      </td>
      <td className="px-3 py-2">
        <input
          type="number"
          step="0.01"
          placeholder="sell"
          value={draft.sellPrice ?? ""}
          onChange={(e) => upd({ sellPrice: e.target.value === "" ? null : e.target.value })}
          className="bg-neutral-900 border border-neutral-700 rounded px-2 py-1 text-sm w-20 text-right placeholder-neutral-600"
        />
      </td>
      <td
        className={`px-3 py-2 text-right text-sm ${
          livePnl === null ? "text-neutral-500" : livePnl > 0 ? "text-gain" : livePnl < 0 ? "text-loss" : "text-neutral-300"
        }`}
      >
        {livePnl === null ? "open" : formatINR(livePnl)}
      </td>
      <td className="px-3 py-2 text-right">
        <button onClick={submit} className="text-xs bg-white text-black rounded px-2 py-1">
          add
        </button>
      </td>
    </tr>
  );
}

export default function Journal() {
  const [trades, setTrades] = useState([]);
  const [err, setErr] = useState(null);
  const [filter, setFilter] = useState("");
  const [segment, setSegment] = useState("All");
  const [sortBy, setSortBy] = useState("date");
  const [sortDir, setSortDir] = useState("desc");

  const reload = () =>
    api.listTrades().then(setTrades).catch((e) => setErr(String(e.message || e)));

  useEffect(() => {
    reload();
  }, []);

  const visible = useMemo(() => {
    let rows = trades;
    if (filter) {
      const q = filter.toUpperCase();
      rows = rows.filter((t) => t.stock.includes(q));
    }
    if (segment !== "All") rows = rows.filter((t) => t.segment === segment);
    rows = [...rows].sort((a, b) => {
      let av = a[sortBy];
      let bv = b[sortBy];
      if (sortBy === "date") {
        av = new Date(av).getTime();
        bv = new Date(bv).getTime();
      } else if (sortBy === "qty") {
        av = a.lotSize * a.lots;
        bv = b.lotSize * b.lots;
      } else if (sortBy === "pnl") {
        av = a.pnl ?? -Infinity;
        bv = b.pnl ?? -Infinity;
      }
      return sortDir === "asc" ? av - bv : bv - av;
    });
    return rows;
  }, [trades, filter, segment, sortBy, sortDir]);

  const toggleSort = (col) => {
    if (sortBy === col) setSortDir(sortDir === "asc" ? "desc" : "asc");
    else {
      setSortBy(col);
      setSortDir("desc");
    }
  };

  const create = async (draft) => {
    try {
      await api.createTrade(draft);
      await reload();
    } catch (e) {
      setErr(String(e.message || e));
    }
  };

  const save = async (draft) => {
    try {
      await api.updateTrade(draft.id, draft);
      await reload();
    } catch (e) {
      setErr(String(e.message || e));
    }
  };

  const remove = async (id) => {
    if (!confirm("Delete this trade?")) return;
    await api.deleteTrade(id);
    reload();
  };

  return (
    <div className="space-y-4">
      {err ? <div className="text-loss text-sm">{err}</div> : null}

      <div className="flex gap-2 items-center">
        <input
          placeholder="Filter symbol…"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          className="bg-neutral-900 border border-neutral-700 rounded px-3 py-1.5 text-sm w-48"
        />
        <select
          value={segment}
          onChange={(e) => setSegment(e.target.value)}
          className="bg-neutral-900 border border-neutral-700 rounded px-3 py-1.5 text-sm"
        >
          <option>All</option>
          <option>Equity</option>
          <option>Futures</option>
          <option>Options</option>
        </select>
        <span className="ml-auto text-xs text-neutral-500">{visible.length} trades</span>
      </div>

      <div className="rounded-lg border border-neutral-800 bg-neutral-900 overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="text-neutral-500 bg-neutral-950">
            <tr>
              <Th onClick={() => toggleSort("date")} active={sortBy === "date"} dir={sortDir}>
                Date
              </Th>
              <th className="text-left px-3 py-2 font-medium">Symbol</th>
              <th className="text-left px-3 py-2 font-medium">Exch</th>
              <th className="text-left px-3 py-2 font-medium">Segment</th>
              <th className="text-left px-3 py-2 font-medium">Dir</th>
              <Th onClick={() => toggleSort("qty")} active={sortBy === "qty"} dir={sortDir} align="right">
                Lot × Qty
              </Th>
              <Th onClick={() => toggleSort("buyPrice")} active={sortBy === "buyPrice"} dir={sortDir} align="right">
                Buy
              </Th>
              <th className="text-right px-3 py-2 font-medium">Sell</th>
              <Th onClick={() => toggleSort("pnl")} active={sortBy === "pnl"} dir={sortDir} align="right">
                P&L
              </Th>
              <th />
            </tr>
          </thead>
          <tbody>
            <AddRow onCreate={create} />
            {visible.map((t) => (
              <TradeRow key={t.id} trade={t} onSave={save} onDelete={remove} />
            ))}
            {visible.length === 0 ? (
              <tr>
                <td colSpan={10} className="px-4 py-8 text-center text-neutral-500">
                  No trades match.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function Th({ children, onClick, active, dir, align = "left" }) {
  return (
    <th
      onClick={onClick}
      className={`px-3 py-2 font-medium cursor-pointer select-none ${align === "right" ? "text-right" : "text-left"} ${
        active ? "text-white" : "text-neutral-500"
      }`}
    >
      {children}
      {active ? <span className="ml-1 text-neutral-400">{dir === "asc" ? "▲" : "▼"}</span> : null}
    </th>
  );
}
