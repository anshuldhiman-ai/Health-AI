// Parser dispatcher. Tries each broker parser in order; falls back to generic.
//
// Flow per CLAUDE.md §5:
//   1. detect file type from extension
//   2. read headers
//   3. try each known broker (zerodha first)
//   4. fall back to generic — return raw headers + rows so the frontend
//      ColumnMapper can drive the mapping.

import * as zerodha from "./zerodha.js";
import * as upstox from "./upstox.js";
import * as groww from "./groww.js";
import * as generic from "./generic.js";

export function detectFileType(filename) {
  const lower = (filename || "").toLowerCase();
  if (lower.endsWith(".csv")) return "csv";
  if (lower.endsWith(".xlsx") || lower.endsWith(".xls")) return "xlsx";
  if (lower.endsWith(".pdf")) return "pdf";
  return "unknown";
}

export async function rowsFromFile(buffer, type) {
  if (type === "csv") {
    const Papa = (await import("papaparse")).default;
    const text = buffer.toString("utf8");
    const parsed = Papa.parse(text, { header: true, skipEmptyLines: true });
    const headers = parsed.meta?.fields || (parsed.data[0] ? Object.keys(parsed.data[0]) : []);
    return { headers, rows: parsed.data };
  }
  if (type === "xlsx") {
    const XLSX = await import("xlsx");
    const wb = XLSX.read(buffer, { type: "buffer" });
    const sheetName = wb.SheetNames[0];
    const sheet = wb.Sheets[sheetName];
    const rows = XLSX.utils.sheet_to_json(sheet, { defval: "" });
    const headers = rows[0] ? Object.keys(rows[0]) : [];
    return { headers, rows };
  }
  if (type === "pdf") {
    // PDF parsing is the lowest-priority step (Step 8). For now, return empty.
    const pdfParse = (await import("pdf-parse")).default;
    const text = await pdfParse(buffer);
    // Heuristic fallback: try to treat the extracted text as CSV if it has commas.
    const lines = String(text.text || "").split(/\r?\n/).filter(Boolean);
    if (lines.length > 0) {
      const Papa = (await import("papaparse")).default;
      const parsed = Papa.parse(lines.join("\n"), { header: true, skipEmptyLines: true });
      const headers = parsed.meta?.fields || (parsed.data[0] ? Object.keys(parsed.data[0]) : []);
      return { headers, rows: parsed.data };
    }
    return { headers: [], rows: [] };
  }
  return { headers: [], rows: [] };
}

// Each broker module exports detect() and parse(). The dispatcher keys off
// detect() to pick one. We tag the broker by which module matched.
export function tryBrokerParse(headers, rows) {
  // Order matters: zerodha first (most common), then upstox, groww.
  const ordered = [
    { name: "zerodha", mod: zerodha },
    { name: "upstox", mod: upstox },
    { name: "groww", mod: groww },
  ];
  for (const { name, mod } of ordered) {
    if (mod.detect(headers)) {
      const result = mod.parse(rows);
      return { broker: name, ...result };
    }
  }
  return null;
}

export { generic };
