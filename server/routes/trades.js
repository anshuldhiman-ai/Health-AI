import { Router } from "express";
import { PrismaClient } from "@prisma/client";
import { computePnl } from "../lib/calc.js";

const prisma = new PrismaClient();
export const tradesRouter = Router();

// Validators — kept inline to avoid a utils file for a small CRUD surface.
function parseDate(v) {
  if (!v) return null;
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return null;
  return d;
}

function normalizeBody(body) {
  const required = ["date", "stock", "exchange", "segment", "direction", "buyPrice", "lots"];
  for (const k of required) {
    if (body[k] === undefined || body[k] === null || body[k] === "") {
      throw new Error(`Missing field: ${k}`);
    }
  }
  const date = parseDate(body.date);
  if (!date) throw new Error("Invalid date");
  if (!["NSE", "BSE"].includes(body.exchange)) throw new Error("exchange must be NSE or BSE");
  if (!["Equity", "Futures", "Options"].includes(body.segment))
    throw new Error("segment must be Equity / Futures / Options");
  if (!["Long", "Short"].includes(body.direction)) throw new Error("direction must be Long or Short");

  const buyPrice = Number(body.buyPrice);
  const sellPrice =
    body.sellPrice === null || body.sellPrice === undefined || body.sellPrice === ""
      ? null
      : Number(body.sellPrice);
  if (Number.isNaN(buyPrice)) throw new Error("buyPrice must be a number");
  if (sellPrice !== null && Number.isNaN(sellPrice)) throw new Error("sellPrice must be a number");

  const lotSize = Number(body.lotSize ?? 1);
  const lots = Number(body.lots);
  const charges = Number(body.charges ?? 0);
  if (Number.isNaN(lotSize) || lotSize < 1) throw new Error("lotSize must be >= 1");
  if (Number.isNaN(lots) || lots <= 0) throw new Error("lots must be > 0");
  if (Number.isNaN(charges) || charges < 0) throw new Error("charges must be >= 0");

  return {
    date,
    stock: String(body.stock).toUpperCase().trim(),
    exchange: body.exchange,
    segment: body.segment,
    direction: body.direction,
    buyPrice,
    sellPrice,
    lotSize: Math.round(lotSize),
    lots,
    charges,
    notes: body.notes ?? null,
    strategy: body.strategy ?? null,
    source: body.source ?? "manual",
    importId: body.importId ?? null,
  };
}

function withPnl(trade) {
  return {
    ...trade,
    pnl: computePnl({
      buyPrice: trade.buyPrice,
      sellPrice: trade.sellPrice,
      lotSize: trade.lotSize,
      lots: trade.lots,
      charges: trade.charges,
      direction: trade.direction,
    }),
  };
}

// GET /api/trades — full list, newest first. Filtering happens client-side for v1.
tradesRouter.get("/", async (_req, res) => {
  const rows = await prisma.trade.findMany({ orderBy: { date: "desc" } });
  res.json(rows.map(withPnl));
});

tradesRouter.get("/stats", async (_req, res) => {
  const rows = await prisma.trade.findMany();
  let netPnl = 0;
  let wins = 0;
  let losses = 0;
  let open = 0;
  let closed = 0;
  let charges = 0;
  const equity = [];

  // Sorted ascending by date for an honest equity curve.
  const sorted = [...rows].sort((a, b) => new Date(a.date) - new Date(b.date));
  let running = 0;
  for (const r of sorted) {
    const p = withPnl(r).pnl;
    if (p !== null) {
      running += p;
      equity.push({ date: r.date, equity: running });
      netPnl += p;
      if (p > 0) wins++;
      else if (p < 0) losses++;
      closed++;
    } else {
      open++;
    }
    charges += r.charges || 0;
  }

  const winRate = wins + losses > 0 ? wins / (wins + losses) : 0;
  res.json({
    netPnl,
    winRate,
    wins,
    losses,
    openCount: open,
    closedCount: closed,
    charges,
    equityCurve: equity,
    totalTrades: rows.length,
  });
});

tradesRouter.get("/:id", async (req, res) => {
  const t = await prisma.trade.findUnique({ where: { id: req.params.id } });
  if (!t) return res.status(404).json({ error: "Trade not found" });
  res.json(withPnl(t));
});

tradesRouter.post("/", async (req, res) => {
  try {
    const data = normalizeBody(req.body);
    const pnl = computePnl(data);
    const created = await prisma.trade.create({ data: { ...data, pnl } });
    res.status(201).json(withPnl(created));
  } catch (e) {
    res.status(400).json({ error: String(e.message || e) });
  }
});

tradesRouter.patch("/:id", async (req, res) => {
  try {
    const existing = await prisma.trade.findUnique({ where: { id: req.params.id } });
    if (!existing) return res.status(404).json({ error: "Trade not found" });
    const merged = normalizeBody({ ...existing, ...req.body });
    const pnl = computePnl(merged);
    const updated = await prisma.trade.update({
      where: { id: req.params.id },
      data: { ...merged, pnl },
    });
    res.json(withPnl(updated));
  } catch (e) {
    res.status(400).json({ error: String(e.message || e) });
  }
});

tradesRouter.delete("/:id", async (req, res) => {
  try {
    await prisma.trade.delete({ where: { id: req.params.id } });
    res.json({ ok: true });
  } catch (e) {
    res.status(404).json({ error: "Trade not found" });
  }
});
