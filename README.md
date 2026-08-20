# Trading Journal

A trading journal web app for an Indian retail trader (NSE/BSE, equity + F&O).

Upload your broker's trade file (CSV/Excel/PDF) and the app parses it into structured trade records. Each trade opens to a chart with your entry and exit marked. Currency is always INR (₹).

See [CLAUDE.md](./CLAUDE.md) for the full specification.

## Stack

- Frontend: React (Vite), Tailwind CSS, lightweight-charts, recharts
- Backend: Node.js + Express
- DB: SQLite via Prisma (schema is Postgres-compatible — swap `provider` in `server/db/schema.prisma` and the `DATABASE_URL` to migrate)
- Parsers: papaparse (CSV), xlsx (Excel), pdf-parse (PDF contract notes, best-effort)

## Layout

```
trading-journal/
├── client/    Vite + React frontend
├── server/    Express API + parsers + market data service
└── CLAUDE.md  source of truth for this project
```

## Setup

```bash
# Server
cd server
cp ../.env.example .env
npm install
npx prisma migrate dev --name init
npm run dev          # http://localhost:4000

# Client (separate terminal)
cd ../client
npm install
npm run dev          # http://localhost:5173
```

## Build order (each step leaves the app runnable)

1. Scaffold + Prisma + Express health check ✅
2. Manual trade CRUD + Journal + Dashboard ✅
3. Generic CSV upload pipeline (dropzone → column mapper → preview → commit) ✅
4. Zerodha tradebook parser (pairs buy/sell, flags open positions) ✅
5. `marketDataService` (placeholder provider) + `TradeChart` (entry/exit markers) ✅
6. Trade Detail page (chart + editable fields) ✅
7. Analytics page (strategy / segment / symbol breakdowns, streaks, monthly P&L) ✅
8. Invest Right parser, PDF path polish, README; Upstox + Groww still pending samples

## Market data

The default `MARKET_DATA_PROVIDER=placeholder` returns deterministic synthetic candles so the UI can be developed without an external API. Swap in a real provider by adding a case in `server/services/marketDataService.js` — the public interface (`getCandles({ symbol, exchange, from, to, interval })`) does not change. API keys must live in `.env` and never reach the client (all requests proxy through `/api/marketdata/:symbol`).

## Broker parsers

| Broker   | Status   | Notes |
|----------|----------|-------|
| Zerodha      | ✅ shipped | Tradebook format. Pairs buy/sell rows; flags unmatched as open positions. |
| Invest Right | ✅ shipped | "Positions Overall" export. Section-aware (`--- Open / Closed Positions ---`); recovers buy/sell from totals and reports P&L from the file. |
| Upstox       | ⏳ pending | Awaiting sample file. |
| Groww        | ⏳ pending | Awaiting sample file. |
| Generic      | ✅ shipped | CSV with manual column-mapping UI. |

## Conventions

- Money stored/transmitted as numbers (₹ values), formatted only at render time.
- Green = gain, Red = loss. Used functionally and consistently — nowhere else.
- P&L math lives in `server/lib/calc.js` and `client/src/lib/calc.js` — never recomputed inline.
- All API calls go through `client/src/api/client.js` — components never `fetch` directly.
