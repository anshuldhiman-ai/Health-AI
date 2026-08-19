// Upstox parser — placeholder for Step 8. detect() returns false until then,
// so the dispatcher skips it. The shape will mirror zerodha.js once built.

export function detect(_headers) {
  return false;
}

export function parse(rows) {
  return { trades: [], unmatched: [], headers: [] };
}
