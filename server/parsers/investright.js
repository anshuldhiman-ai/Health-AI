// "Invest Right Positions Overall" style export.
//
// File shape (from real sample):
//   --- Open Positions ---
//   SYMBOL, ACTION, TYPE, NET QTY, AVG PRICE, LTP, PROFIT & LOSS,
//     TOTAL BUY QTY, TOTAL SELL QTY, TOTAL BUY VALUE, TOTAL SELL VALUE, NET VALUE
//   row1...
//
//   --- Closed Positions ---
//   same header
//   row2...
//
// Notes:
//   - One row per symbol, not per leg.
//   - TYPE = "BUY" or "SELL" describes the user's net side.
//   - For closed positions we recover buyPrice from TOTAL BUY VALUE / TOTAL BUY QTY
//     and sellPrice from TOTAL SELL VALUE / TOTAL SELL QTY. P&L from the column.
//   - For open positions sellPrice is null and we set notes accordingly.
//   - Symbol strings encode the underlying (e.g. "NIFTY 25 Aug 2026 25000.00 CE")
//     so we put the whole string in `stock` and let the user rename later if needed.

const HEADER_LINE =
  '"SYMBOL","ACTION","TYPE","NET QTY","AVG PRICE","LTP","PROFIT & LOSS","TOTAL BUY QTY","TOTAL SELL QTY","TOTAL BUY VALUE","TOTAL SELL VALUE","NET VALUE"';

export function detect(headers) {
  // The CSV doesn't expose "headers" before we split by section — so we accept
  // either the column header line itself, OR a sentinel from the dispatcher's
  // pre-check. This parser is invoked from a section-aware path (see below).
  if (!Array.isArray(headers)) return false;
  const lower = headers.map((h) => String(h).toLowerCase().trim());
  const need = ["symbol", "type", "net qty", "avg price", "ltp", "profit & loss"];
  return need.every((n) => lower.some((h) => h === n));
}

// Section-aware entry point. Used by the dispatcher when we know the file
// matches the marker format (`--- Open Positions ---` etc).
//
// `rawText` is the full CSV text. We split by the section markers and parse
// each block independently.
export function parseSections(rawText) {
  if (!rawText || typeof rawText !== "string") return { trades: [], unmatched: [] };

  const sections = splitBySections(rawText);
  const trades = [];
  const unmatched = [];

  for (const section of sections) {
    if (section.rows.length === 0) continue;
    for (const r of section.rows) {
      const t = buildTradeFromRow(r, section.kind);
      if (!t) continue;
      if (section.kind === "open") unmatched.push(t);
      else trades.push(t);
    }
  }

  return { trades, unmatched };
}

// Convenience: parse() works like the other brokers — given an array of
// already-extracted row objects keyed by the columns above.
export function parse(rows) {
  // rows[] here are objects keyed by header. We can't tell open vs closed from
  // the row alone, so we treat any row with PnL != 0 as closed and PnL == 0
  // (and net qty != 0) as open. This matches what the dispatcher sees for a
  // single flat block — sectioned parsing above is the richer path.
  const trades = [];
  const unmatched = [];
  for (const r of rows) {
    const lower = {};
    for (const k of Object.keys(r)) lower[k.toLowerCase().trim()] = r[k];
    const t = buildTradeFromRow(lower, "auto");
    if (!t) continue;
    const pnl = Number(lower["profit & loss"] ?? lower["profit & loss a/c"]);
    if (pnl !== 0) trades.push(t);
    else unmatched.push(t);
  }
  return { trades, unmatched };
}

function splitBySections(text) {
  const out = [];
  const re = /---\s*(Open|Closed)\s+Positions\s*---/gi;
  let match;
  const starts = [];
  while ((match = re.exec(text)) !== null) {
    starts.push({ idx: match.index, end: re.lastIndex, kind: match[1].toLowerCase() });
  }
  for (let i = 0; i < starts.length; i++) {
    const s = starts[i];
    const next = starts[i + 1]?.idx ?? text.length;
    const block = text.slice(s.end, next).trim();
    const lines = block.split(/\r?\n/).filter(Boolean);
    if (lines.length === 0) {
      out.push({ kind: s.kind, rows: [] });
      continue;
    }
    // First line is the header (matches HEADER_LINE). Papa would be overkill here
    // since the file is small — use a tolerant CSV split.
    const headerLine = lines[0];
    if (!/symbol/i.test(headerLine)) {
      out.push({ kind: s.kind, rows: [] });
      continue;
    }
    const headers = splitCsvLine(headerLine).map((h) => h.toLowerCase().trim());
    const rows = [];
    for (let li = 1; li < lines.length; li++) {
      const cells = splitCsvLine(lines[li]);
      if (cells.every((c) => c === "")) continue;
      const obj = {};
      headers.forEach((h, i) => (obj[h] = cells[i] ?? ""));
      rows.push(obj);
    }
    out.push({ kind: s.kind, rows });
  }
  return out;
}

// Minimal CSV-line splitter handling quoted values with embedded commas.
// Tolerant of spaces inside quotes.
function splitCsvLine(line) {
  const out = [];
  let cur = "";
  let inQ = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      // Doubled quote inside a quoted field = literal quote.
      if (inQ && line[i + 1] === '"') {
        cur += '"';
        i++;
      } else {
        inQ = !inQ;
      }
    } else if (ch === "," && !inQ) {
      out.push(cur);
      cur = "";
    } else {
      cur += ch;
    }
  }
  out.push(cur);
  return out;
}

function buildTradeFromRow(lower, kind) {
  const symbol = String(lower["symbol"] ?? "").trim();
  if (!symbol) return null;

  const typeRaw = String(lower["type"] ?? "BUY").toUpperCase();
  const direction = typeRaw === "SELL" ? "Short" : "Long";

  const netQty = Number(lower["net qty"]);
  const totalBuyQty = Number(lower["total buy qty"]);
  const totalSellQty = Number(lower["total sell qty"]);
  const totalBuyValue = Number(lower["total buy value"]);
  const totalSellValue = Number(lower["total sell value"]);
  const avgPrice = Number(lower["avg price"]);
  const pnlReported = Number(lower["profit & loss"] ?? 0);

  // Prefer VWAP from totals — that's what "AVG PRICE" really is on this export.
  const buyPrice = totalBuyQty > 0 ? totalBuyValue / totalBuyQty : avgPrice;
  const sellPrice = totalSellQty > 0 ? totalSellValue / totalSellQty : null;

  // Quantity the user actually traded in this leg. For closed trades we use the
  // matched-pair quantity (min of buy/sell totals). For open positions it's the
  // current net qty.
  const lots = Math.max(totalBuyQty, totalSellQty, Math.abs(netQty)) || Math.abs(netQty);

  // Lot size: 1 for equity-style; F&O symbols carry the contract in the name
  // so we leave lotSize = 1 and let the user correct lot count in preview.
  const lotSize = 1;

  // Segment from the symbol hint — options/futures have strike/expiry in the name.
  const segment = inferSegment(symbol);

  // Notes carry the human-meaningful tag so the user sees what was imported.
  const tag = pnlReported !== 0 ? `Reported P&L: ${pnlReported}` : "Open position";
  const notes = `Invest Right import · ${tag}`;

  return {
    date: new Date(), // The file doesn't carry a per-row date — stamp today.
    stock: symbol,
    exchange: "NSE",
    segment,
    direction,
    buyPrice,
    sellPrice,
    lotSize,
    lots,
    charges: 0,
    source: "investright",
    notes,
    strategy: null,
  };
}

function inferSegment(symbol) {
  const s = symbol.toUpperCase();
  if (/\b(CE|PE)\b/.test(s)) return "Options";
  if (/\b(FUT)\b/.test(s)) return "Futures";
  return "Equity";
}
