// Mirror of server/lib/calc.js — keep semantics in sync.
// Used for optimistic UI and inline validation; the server is the source of truth.

export function qty(lotSize, lots) {
  return Number(lotSize) * Number(lots);
}

export function computePnl({ buyPrice, sellPrice, lotSize, lots, charges, direction }) {
  if (sellPrice === null || sellPrice === undefined) return null;
  const q = qty(lotSize, lots);
  const gross =
    direction === "Short"
      ? (Number(buyPrice) - Number(sellPrice)) * q
      : (Number(sellPrice) - Number(buyPrice)) * q;
  return gross - Number(charges || 0);
}

export function isOpen(trade) {
  return trade.sellPrice === null || trade.sellPrice === undefined;
}

export function formatINR(n) {
  if (n === null || n === undefined || Number.isNaN(Number(n))) return "₹0";
  return "₹" + Number(n).toLocaleString("en-IN", { maximumFractionDigits: 2 });
}

export function formatINRShort(n) {
  if (n === null || n === undefined) return "₹0";
  const v = Number(n);
  const abs = Math.abs(v);
  if (abs >= 1e7) return (v < 0 ? "-" : "") + "₹" + (abs / 1e7).toFixed(2) + "Cr";
  if (abs >= 1e5) return (v < 0 ? "-" : "") + "₹" + (abs / 1e5).toFixed(2) + "L";
  if (abs >= 1e3) return (v < 0 ? "-" : "") + "₹" + (abs / 1e3).toFixed(1) + "k";
  return "₹" + v.toFixed(0);
}
