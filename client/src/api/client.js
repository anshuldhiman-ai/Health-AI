// Single API surface — components import from here, never call fetch directly.
// Base URL is proxied through Vite in dev; in prod, the server serves the build.

const BASE = ""; // proxied

async function jsonOrThrow(res) {
  const text = await res.text();
  let body;
  try {
    body = text ? JSON.parse(text) : null;
  } catch {
    body = text;
  }
  if (!res.ok) {
    throw new Error(typeof body === "string" ? body : body?.error || `HTTP ${res.status}`);
  }
  return body;
}

export const api = {
  // Trades (Step 2)
  listTrades: () => fetch(`${BASE}/api/trades`).then(jsonOrThrow),
  getTrade: (id) => fetch(`${BASE}/api/trades/${id}`).then(jsonOrThrow),
  createTrade: (trade) =>
    fetch(`${BASE}/api/trades`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(trade),
    }).then(jsonOrThrow),
  updateTrade: (id, patch) =>
    fetch(`${BASE}/api/trades/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(patch),
    }).then(jsonOrThrow),
  deleteTrade: (id) =>
    fetch(`${BASE}/api/trades/${id}`, { method: "DELETE" }).then(jsonOrThrow),
  dashboardStats: () => fetch(`${BASE}/api/trades/stats`).then(jsonOrThrow),

  // Upload (Step 3)
  uploadPreview: (formData) =>
    fetch(`${BASE}/api/upload`, { method: "POST", body: formData }).then(jsonOrThrow),
  uploadCommit: (payload) =>
    fetch(`${BASE}/api/upload/commit`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    }).then(jsonOrThrow),

  // Market data (Step 5)
  getCandles: ({ symbol, exchange, from, to, interval }) => {
    const qs = new URLSearchParams({ exchange, from, to, interval });
    return fetch(`${BASE}/api/marketdata/${encodeURIComponent(symbol)}?${qs}`).then(jsonOrThrow);
  },
};
