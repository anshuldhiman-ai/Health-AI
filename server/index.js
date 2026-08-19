import "dotenv/config";
import express from "express";
import cors from "cors";
import { PrismaClient } from "@prisma/client";
import { tradesRouter } from "./routes/trades.js";
import { uploadRouter } from "./routes/upload.js";
import { marketDataRouter } from "./routes/marketdata.js";

const prisma = new PrismaClient();
const app = express();

app.use(cors());
app.use(express.json({ limit: "20mb" }));

// Health check — proves the server is up and the DB is reachable.
app.get("/health", async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    res.json({ ok: true, db: "up" });
  } catch (e) {
    res.status(500).json({ ok: false, error: String(e) });
  }
});

app.use("/api/trades", tradesRouter);
app.use("/api/upload", uploadRouter);
app.use("/api/marketdata", marketDataRouter);

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`[server] listening on http://localhost:${PORT}`);
});
