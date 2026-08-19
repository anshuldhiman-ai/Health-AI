// Generic parser — does NOT auto-map. It returns the raw headers + rows
// so the frontend ColumnMapper UI can drive the mapping.
//
// detect() is always false — this is the fallback, not a candidate format.
// parse() returns the parsed shape so /api/upload can hand it back to the UI.

export function detect(_headers) {
  return false;
}

// rows is an array of objects keyed by header name (papaparse with header:true).
// We return headers + rows verbatim so the column mapper has the full info.
export function parse(rows) {
  if (!rows || rows.length === 0) {
    return { headers: [], rows: [], mapped: [] };
  }
  const headers = Object.keys(rows[0]);
  return { headers, rows, mapped: [] };
}
