import { Router } from "express";
import multer from "multer";
import { PrismaClient } from "@prisma/client";
import { computePnl } from "../lib/calc.js";
import {
  detectFileType,
  rowsFromFile,
  tryBrokerParse,
  tryBrokerParseByText,
  generic,
} from "../parsers/index.js";

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 20 * 1024 * 1024 } });
const prisma = new PrismaClient();
export const uploadRouter = Router();

// POST /api/upload  — multipart, field name "file"
// Returns one of:
//   { broker: "zerodha", rows: [Trade...] }  on broker match
//   { broker: "generic", headers, rows }     when fallback is needed (caller maps)
//   { broker: "generic", mapped }            when caller already supplied a mapping
uploadRouter.post("/", upload.single("file"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded" });
    const type = detectFileType(req.file.originalname);
    if (type === "unknown")
      return res.status(400).json({ error: "Unsupported file type (csv/xlsx/pdf only)" });

    const { headers, rows, rawText } = await rowsFromFile(req.file.buffer, type);

    // 1a. Section-marker parsers (e.g. Invest Right's "--- Open Positions ---" blocks)
    //     need raw text. Try this first because the CSV-flatten path would lose them.
    const byText = tryBrokerParseByText(rawText);
    if (byText) {
      return res.json({
        broker: byText.broker,
        headers,
        rows: [...byText.trades, ...byText.unmatched],
        detected: true,
      });
    }

    // 1b. Try a known broker parser keyed off headers.
    const brokerResult = tryBrokerParse(headers, rows, rawText);
    if (brokerResult) {
      return res.json({
        broker: brokerResult.broker,
        headers,
        rows: [...brokerResult.trades, ...brokerResult.unmatched],
        detected: true,
      });
    }

    // 2. Generic fallback — return raw headers/rows for the column mapper.
    const fallback = generic.parse(rows);
    res.json({
      broker: "generic",
      headers: fallback.headers,
      rows: fallback.rows,
      detected: false,
    });
  } catch (e) {
    res.status(500).json({ error: String(e.message || e) });
  }
});

// POST /api/upload/commit  — { broker, filename, rows: [Trade...] }
// Writes trades + one ImportBatch in a single transaction.
uploadRouter.post("/commit", async (req, res) => {
  try {
    const { broker = "generic", filename = "upload", rows } = req.body || {};
    if (!Array.isArray(rows) || rows.length === 0) {
      return res.status(400).json({ error: "No rows to commit" });
    }

    // Normalize each row through the same path as the manual endpoint,
    // so a bad row is rejected loudly rather than silently written.
    const prepared = rows.map((r) => {
      const sellPrice =
        r.sellPrice === null || r.sellPrice === undefined || r.sellPrice === ""
          ? null
          : Number(r.sellPrice);
      const data = {
        date: new Date(r.date),
        stock: String(r.stock).toUpperCase().trim(),
        exchange: r.exchange,
        segment: r.segment,
        direction: r.direction,
        buyPrice: Number(r.buyPrice),
        sellPrice,
        lotSize: Number(r.lotSize ?? 1),
        lots: Number(r.lots),
        charges: Number(r.charges ?? 0),
        notes: r.notes ?? null,
        strategy: r.strategy ?? null,
        source: broker,
      };
      const pnl = computePnl(data);
      return { ...data, pnl };
    });

    const batch = await prisma.importBatch.create({
      data: { broker, filename, rowCount: prepared.length },
    });

    const created = await prisma.$transaction(
      prepared.map((p) =>
        prisma.trade.create({ data: { ...p, importId: batch.id } })
      )
    );

    res.json({ ok: true, batchId: batch.id, count: created.length });
  } catch (e) {
    res.status(400).json({ error: String(e.message || e) });
  }
});
