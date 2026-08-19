// Column mapping UI — shown when the generic parser was used.
// User picks one source column per destination field, or "(none)" to skip.

const FIELDS = [
  { key: "date", label: "Date", required: true },
  { key: "stock", label: "Symbol", required: true },
  { key: "exchange", label: "Exchange (NSE/BSE)", required: true },
  { key: "segment", label: "Segment (Equity/Futures/Options)", required: true },
  { key: "direction", label: "Direction (Long/Short)", required: true },
  { key: "buyPrice", label: "Buy Price", required: true },
  { key: "sellPrice", label: "Sell Price (leave empty for open positions)", required: false },
  { key: "lots", label: "Lots / Quantity", required: true },
  { key: "lotSize", label: "Lot Size (default 1)", required: false },
  { key: "charges", label: "Charges", required: false },
];

// Best-guess mapping based on header-name heuristics. User can override.
function autoGuess(headers) {
  const lower = headers.map((h) => h.toLowerCase());
  const find = (...needles) => {
    for (const n of needles) {
      const i = lower.findIndex((h) => h.includes(n));
      if (i !== -1) return headers[i];
    }
    return "";
  };
  return {
    date: find("date", "trade_date"),
    stock: find("symbol", "scrip", "stock"),
    exchange: find("exchange"),
    segment: find("segment"),
    direction: find("buy/sell", "type", "side", "direction"),
    buyPrice: find("buy_price", "buy rate", "buy price", "price"),
    sellPrice: find("sell_price", "sell rate", "sell price"),
    lots: find("qty", "quantity", "lots"),
    lotSize: find("lot_size", "lot size"),
    charges: find("charges", "brokerage", "fees"),
  };
}

export default function ColumnMapper({ headers, mapping, onChange, onApply, onCancel }) {
  const update = (key, value) => onChange({ ...mapping, [key]: value });

  return (
    <div className="rounded-lg border border-neutral-800 bg-neutral-900 p-4 space-y-3">
      <div className="text-sm text-neutral-300">
        We couldn't auto-detect a broker. Map your file's columns to the trade fields below.
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
        {FIELDS.map((f) => (
          <div key={f.key} className="flex items-center gap-2">
            <label className="text-sm text-neutral-300 w-48">
              {f.label}
              {f.required ? <span className="text-loss ml-1">*</span> : null}
            </label>
            <select
              value={mapping[f.key] || ""}
              onChange={(e) => update(f.key, e.target.value)}
              className="bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm flex-1"
            >
              <option value="">(none)</option>
              {headers.map((h) => (
                <option key={h} value={h}>
                  {h}
                </option>
              ))}
            </select>
          </div>
        ))}
      </div>
      <div className="flex justify-end gap-2 pt-2">
        <button onClick={onCancel} className="px-3 py-1.5 text-sm text-neutral-400 hover:text-white">
          Cancel
        </button>
        <button onClick={onApply} className="px-3 py-1.5 text-sm bg-white text-black rounded">
          Build preview
        </button>
      </div>
    </div>
  );
}

// Apply a {field: sourceColumn} mapping to an array of raw rows, producing
// Trade-shaped rows in the preview table.
export function applyMapping(rows, mapping, headers) {
  const get = (row, key) => {
    const col = mapping[key];
    if (!col) return undefined;
    return row[col];
  };

  const fallbackExchange = headers.find((h) => /exchange/i.test(h)) ? "NSE" : "NSE";
  const out = [];
  for (const r of rows) {
    const stock = String(get(r, "stock") ?? "").trim();
    if (!stock) continue;
    const dateRaw = get(r, "date");
    const date = dateRaw ? new Date(dateRaw) : new Date();
    const sellPriceRaw = get(r, "sellPrice");
    const sellPrice =
      sellPriceRaw === undefined || sellPriceRaw === null || sellPriceRaw === ""
        ? null
        : Number(sellPriceRaw);
    out.push({
      date: date.toISOString(),
      stock: stock.toUpperCase(),
      exchange: get(r, "exchange") || fallbackExchange,
      segment: get(r, "segment") || "Equity",
      direction: get(r, "direction") || "Long",
      buyPrice: Number(get(r, "buyPrice")),
      sellPrice: Number.isNaN(sellPrice) ? null : sellPrice,
      lotSize: Number(get(r, "lotSize") || 1),
      lots: Number(get(r, "lots")),
      charges: Number(get(r, "charges") || 0),
      notes: "",
      strategy: "",
    });
  }
  return out;
}

export { autoGuess, FIELDS };
