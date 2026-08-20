// Parser dispatcher. Tries each broker parser in order; falls back to generic.
//
// Flow per CLAUDE.md §5:
//   1. detect file type from extension
//   2. read headers / extract rows
//   3. try each known broker (zerodha first)
//   4. fall back to generic — return raw headers + rows so the frontend
//      ColumnMapper can drive the mapping.

import * as zerodha from "./zerodha.js";
import * as upstox from "./upstox.js";
import * as groww from "./groww.js";
import * as investright from "./investright.js";
import * as generic from "./generic.js";

export function detectFileType(filename) {
  const lower = (filename || "").toLowerCase();
  if (lower.endsWith(".csv")) return "csv";
  if (lower.endsWith(".xlsx") || lower.endsWith(".xls")) return "xlsx";
  if (lower.endsWith(".pdf")) return "pdf";
  return "unknown";
}

// Pre-detection for parsers that don't expose headers via the standard CSV/XLSX
// path — e.g. sectioned text formats. Returns a broker name if matched.
export function detectByText(rawText) {
  if (!rawText || typeof rawText !== "string") return null;
  if (
    /---\s*Open Positions\s*---/i.test(rawText) &&
    /---\s*Closed Positions\s*---/i.test(rawText)
  ) {
    return "investright";
  }
  return null;
}

export async function rowsFromFile(buffer, type) {
  if (type === "csv") {
    const Papa = (await import("papaparse")).default;
    const text = buffer.toString("utf8");
    const parsed = Papa.parse(text, { header: true, skipEmptyLines: true });
    const headers = parsed.meta?.fields || (parsed.data[0] ? Object.keys(parsed.data[0]) : []);
    return { headers, rows: parsed.data, rawText: text };
  }
  if (type === "xlsx") {
    const XLSX = await import("xlsx");
    const wb = XLSX.read(buffer, { type: "buffer" });
    const sheetName = wb.SheetNames[0];
    const sheet = wb.Sheets[sheetName];
    const rows = XLSX.utils.sheet_to_json(sheet, { defval: "" });
    const headers = rows[0] ? Object.keys(rows[0]) : [];
    return { headers, rows, rawText: null };
  }
  if (type === "pdf") {
    const pdfParse = (await import("pdf-parse")).default;
    const result = await pdfParse(buffer);
    const text = String(result.text || "");

    const lines = text
      .split(/\r?\n/)
      .map((l) => l.trim())
      .filter(Boolean);

    if (lines.length === 0) return { headers: [], rows: [], rawText: text };

    const headerIdx = lines.findIndex((l) => (l.match(/,/g) || []).length >= 3);
    if (headerIdx !== -1) {
      const Papa = (await import("papaparse")).default;
      const tableText = lines.slice(headerIdx).join("\n");
      const parsed = Papa.parse(tableText, { header: true, skipEmptyLines: true });
      const headers = parsed.meta?.fields || (parsed.data[0] ? Object.keys(parsed.data[0]) : []);
      return { headers, rows: parsed.data, rawText: text };
    }

    return {
      headers: ["raw_text"],
      rows: lines.slice(0, 200).map((line) => ({ raw_text: line })),
      rawText: text,
    };
  }
  return { headers: [], rows: [], rawText: null };
}

// Each broker module exports detect() and parse(). The dispatcher keys off
// detect() to pick one. We tag the broker by which module matched.
//
// The `rawText` argument is the full extracted text for parsers that need
// section markers (e.g. Invest Right's `--- Open Positions ---` blocks).
export function tryBrokerParse(headers, rows, rawText) {
  const ordered = [
    { name: "zerodha", mod: zerodha },
    { name: "upstox", mod: upstox },
    { name: "groww", mod: groww },
    { name: "investright", mod: investright, useText: true },
  ];
  for (const { name, mod, useText } of ordered) {
    if (mod.detect(headers)) {
      const result = useText && rawText ? mod.parseSections(rawText) : mod.parse(rows);
      return { broker: name, ...result };
    }
  }
  return null;
}

// Section-aware variant. Use this when you want to bypass the standard CSV
// header flow and detect by file content (e.g. Invest Right's marker format).
export function tryBrokerParseByText(rawText) {
  const broker = detectByText(rawText);
  if (broker === "investright") {
    const result = investright.parseSections(rawText);
    return { broker, ...result };
  }
  return null;
}

export { generic };
