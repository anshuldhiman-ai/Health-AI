// Zerodha tradebook parser — built in Step 4, but registered here so the
// dispatcher can route to it. detect() matches the documented header set.
//
// Reference columns: symbol, isin, trade_date, exchange, segment, series,
//                    trade_type, auction, quantity, price, trade_id,
//                    order_id, order_execution_time

const ZERODHA_HEADERS = [
  "symbol",
  "isin",
  "trade_date",
  "exchange",
  "segment",
  "series",
  "trade_type",
  "auction",
  "quantity",
  "price",
  "trade_id",
  "order_id",
  "order_execution_time",
];

export function detect(headers) {
  if (!Array.isArray(headers) || headers.length === 0) return false;
  const lower = headers.map((h) => String(h).toLowerCase().trim());
  // Require at least the distinctive set: trade_id + symbol + trade_type + quantity + price.
  const need = ["trade_id", "symbol", "trade_type", "quantity", "price"];
  return need.every((n) => lower.includes(n));
}

// Pair buys with subsequent sells on the same symbol (and segment) into one Trade.
// Unmatched rows become open positions (sellPrice = null).
export function parse(rows) {
  const trades = [];
  const unmatched = [];
  const bySymbol = new Map();

  for (const r of rows) {
    const lower = {};
    for (const k of Object.keys(r)) lower[k.toLowerCase().trim()] = r[k];

    const symbol = String(lower.symbol || "").trim();
    const segment = String(lower.segment || "").trim();
    if (!symbol) continue;

    const qty = Number(lower.quantity);
    const price = Number(lower.price);
    if (!Number.isFinite(qty) || !Number.isFinite(price)) continue;

    const date = parseDate(lower.trade_date || lower.order_execution_time);
    const exchange = String(lower.exchange || "NSE").toUpperCase();
    const direction = String(lower.trade_type || "").toUpperCase(); // "BUY" or "SELL"
    if (!["BUY", "SELL"].includes(direction)) continue;

    const key = `${symbol}|${segment}`;
    const list = bySymbol.get(key) || [];

    if (direction === "BUY") {
      // Try to pair with an unmatched SELL of equal quantity on the same symbol.
      const sellIdx = list.findIndex(
        (s) => s.direction === "SELL" && s.remainingQty === qty
      );
      if (sellIdx !== -1) {
        const sell = list[sellIdx];
        list.splice(sellIdx, 1);
        const lotSize = inferLotSize(segment, symbol);
        const lots = qty / lotSize;
        trades.push({
          date: sell.date,
          stock: symbol.toUpperCase(),
          exchange,
          segment: normalizeSegment(segment),
          direction: "Long",
          buyPrice: price,
          sellPrice: sell.price,
          lotSize,
          lots,
          charges: 0,
          source: "zerodha",
          notes: null,
          strategy: null,
        });
        // Any leftover on the sell side becomes an open short? Unlikely for equity.
        // We discard leftovers rather than invent positions.
      } else {
        // Stash as a pending buy — will match with a later SELL.
        list.push({ direction, date, price, remainingQty: qty });
      }
    } else {
      // SELL — first try to pair with a pending BUY of same qty; else unmatched.
      const buyIdx = list.findIndex(
        (b) => b.direction === "BUY" && b.remainingQty === qty
      );
      if (buyIdx !== -1) {
        const buy = list[buyIdx];
        list.splice(buyIdx, 1);
        const lotSize = inferLotSize(segment, symbol);
        const lots = qty / lotSize;
        trades.push({
          date,
          stock: symbol.toUpperCase(),
          exchange,
          segment: normalizeSegment(segment),
          direction: "Long",
          buyPrice: buy.price,
          sellPrice: price,
          lotSize,
          lots,
          charges: 0,
          source: "zerodha",
          notes: null,
          strategy: null,
        });
      } else {
        unmatched.push({
          date,
          stock: symbol.toUpperCase(),
          exchange,
          segment: normalizeSegment(segment),
          direction: "Long",
          buyPrice: price, // sell leg without a known buy — flag as open
          sellPrice: null,
          lotSize: inferLotSize(segment, symbol),
          lots: qty / inferLotSize(segment, symbol),
          charges: 0,
          source: "zerodha",
          notes: "Unmatched sell — flagged as open position",
          strategy: null,
        });
      }
    }

    bySymbol.set(key, list);
  }

  // Anything still in bySymbol is an unmatched BUY (open long).
  for (const [key, list] of bySymbol.entries()) {
    const [symbol, segment] = key.split("|");
    for (const b of list) {
      if (b.direction !== "BUY") continue;
      const lotSize = inferLotSize(segment, symbol);
      unmatched.push({
        date: b.date,
        stock: symbol.toUpperCase(),
        exchange: "NSE",
        segment: normalizeSegment(segment),
        direction: "Long",
        buyPrice: b.price,
        sellPrice: null,
        lotSize,
        lots: b.remainingQty / lotSize,
        charges: 0,
        source: "zerodha",
        notes: "Open position — no matching sell in this file",
        strategy: null,
      });
    }
  }

  return { trades, unmatched, headers: ZERODHA_HEADERS };
}

function parseDate(v) {
  if (!v) return new Date();
  // Zerodha format examples: "2024-01-15" or "2024-01-15 09:30:00"
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? new Date() : d;
}

function normalizeSegment(s) {
  const u = String(s || "").toUpperCase();
  if (u === "EQ" || u === "EQUITY") return "Equity";
  if (u === "FUT" || u === "FUTURES" || u === "FO") return "Futures";
  if (u === "OPT" || u === "OPTIONS") return "Options";
  return "Equity";
}

// Lot size is best inferred per symbol — but for a generic importer we use 1
// for equity and leave F&O to be corrected by the user in the preview table.
function inferLotSize(segment, _symbol) {
  const u = String(segment || "").toUpperCase();
  if (u === "EQ" || u === "EQUITY") return 1;
  return 1; // F&O lot sizes vary — let the user correct in preview.
}
