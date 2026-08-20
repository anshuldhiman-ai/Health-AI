import { Router } from "express";
import { getCandles, activeProvider } from "../services/marketDataService.js";

export const marketDataRouter = Router();

// GET /api/marketdata/:symbol?exchange=NSE&from=YYYY-MM-DD&to=YYYY-MM-DD&interval=1d
// All market data requests are proxied through here so API keys never reach the
// client. The shape of this response is the only thing the client depends on.
marketDataRouter.get("/:symbol", async (req, res) => {
  try {
    const { symbol } = req.params;
    const { exchange = "NSE", from, to, interval = "1d" } = req.query;
    if (!from || !to) {
      return res.status(400).json({ error: "from and to are required (YYYY-MM-DD)" });
    }
    const candles = await getCandles({ symbol, exchange, from, to, interval });
    res.json({ symbol, exchange, interval, provider: activeProvider, candles });
  } catch (e) {
    res.status(400).json({ error: String(e.message || e) });
  }
});
