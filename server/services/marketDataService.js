// Market data service — single interface per CLAUDE.md §6.
//
//   async function getCandles({ symbol, exchange, from, to, interval })
//     -> [{ time: 'YYYY-MM-DD' or epochSeconds, open, high, low, close, volume }]
//
// Today: provider = "placeholder" — synthesizes a deterministic random-walk so
// the UI can be developed end-to-end without an external dependency. Swap in
// Kite Connect or another paid provider by adding another switch case; the
// interface and the proxy route must NOT change.
//
// Rate limits / gaps for the placeholder: no rate limit, no gap-filling beyond
// business-day weekdays, weekends skipped. Documented in README.

const PROVIDER = (process.env.MARKET_DATA_PROVIDER || "placeholder").toLowerCase();

function seededRandom(seed) {
  // Mulberry32 — small, deterministic, good enough for synthetic candles.
  let a = seed >>> 0;
  return function () {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function hashStr(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function daysBetween(from, to) {
  const out = [];
  const d = new Date(from);
  d.setUTCHours(0, 0, 0, 0);
  const end = new Date(to);
  end.setUTCHours(0, 0, 0, 0);
  while (d <= end) {
    const day = d.getUTCDay();
    if (day !== 0 && day !== 6) out.push(new Date(d));
    d.setUTCDate(d.getUTCDate() + 1);
  }
  return out;
}

// Placeholder provider — deterministic synthetic candles seeded on the symbol,
// so the same symbol + range always produces the same series. Good for dev.
function placeholderCandles({ symbol, exchange, from, to, interval }) {
  const seed = hashStr(`${symbol}|${exchange}|${interval || "1d"}`);
  const rnd = seededRandom(seed);
  const days = daysBetween(from, to);

  // Start price seeded from symbol too — gives each ticker a believable base.
  let price = 50 + (seed % 4000);
  const drift = ((seed % 7) - 3) * 0.0005; // small daily drift
  const vol = 0.015; // 1.5% daily volatility

  const out = [];
  for (const day of days) {
    const ret = drift + (rnd() - 0.5) * vol;
    const open = price;
    const close = price * (1 + ret);
    const high = Math.max(open, close) * (1 + rnd() * 0.005);
    const low = Math.min(open, close) * (1 - rnd() * 0.005);
    const volume = Math.floor(rnd() * 1_000_000 + 100_000);
    out.push({
      time: day.toISOString().slice(0, 10),
      open: round2(open),
      high: round2(high),
      low: round2(low),
      close: round2(close),
      volume,
    });
    price = close;
  }
  return out;
}

function round2(n) {
  return Math.round(n * 100) / 100;
}

// Public API. Only one entry point. Components must never import a provider directly.
export async function getCandles({ symbol, exchange, from, to, interval = "1d" }) {
  if (!symbol) throw new Error("symbol required");
  const f = new Date(from);
  const t = new Date(to);
  if (Number.isNaN(f.getTime()) || Number.isNaN(t.getTime())) {
    throw new Error("from/to must be valid dates");
  }
  if (f > t) throw new Error("from must be <= to");

  switch (PROVIDER) {
    case "placeholder":
      return placeholderCandles({ symbol, exchange, from: f, to: t, interval });
    // case "kite": return kiteCandles(...)
    default:
      // Unknown provider falls back to placeholder so the UI never breaks.
      return placeholderCandles({ symbol, exchange, from: f, to: t, interval });
  }
}

export const activeProvider = PROVIDER;
