# CLAUDE.md — Trading Journal App

This file is the source of truth for building this project. Read it fully before writing code. If a requirement here conflicts with a later ad-hoc instruction, ask before deviating from the architecture (not from small implementation details).

## 1. What this project is

A trading journal web app for an Indian retail trader (NSE/BSE, equity + F&O). Instead of manual-only entry, the user uploads their broker's trade file (CSV/Excel/PDF export) and the app parses it into structured trade records. Each trade can be opened to see a live/historical price chart for that symbol with the user's entry and exit marked on it. Currency is always INR (₹).

Core loop: **upload trades → auto-parsed into the journal → user reviews/annotates → dashboard shows P&L, win rate, equity curve → click a trade → see it on a live chart.**

## 2. Tech stack (do not substitute without asking)

- **Frontend**: React (Vite), Tailwind CSS
- **Charts**: `lightweight-charts` (TradingView's open-source library) for trade detail candlestick charts; `recharts` is fine for dashboard stat charts (equity curve, bar breakdowns)
- **Backend**: Node.js + Express
- **Database**: SQLite via Prisma ORM for local/dev (schema should be Postgres-compatible so it's a one-line swap later)
- **File parsing**: `papaparse` (CSV), `xlsx` (Excel), `pdf-parse` (PDF contract notes — lowest priority, build last)
- **Market data**: abstracted behind a single service interface (see §6) — do not hardcode a specific provider's shape into components

## 3. Repo structure

Build exactly this layout:

```
trading-journal/
├── client/
│   ├── src/
│   │   ├── pages/
│   │   │   ├── Dashboard.jsx
│   │   │   ├── Journal.jsx
│   │   │   ├── TradeDetail.jsx
│   │   │   ├── Upload.jsx
│   │   │   └── Analytics.jsx
│   │   ├── components/
│   │   │   ├── TradeChart.jsx
│   │   │   ├── TradeTable.jsx
│   │   │   ├── TradeRowForm.jsx
│   │   │   ├── UploadDropzone.jsx
│   │   │   ├── UploadPreviewTable.jsx
│   │   │   ├── ColumnMapper.jsx
│   │   │   └── StatCard.jsx
│   │   ├── api/
│   │   │   └── client.js
│   │   ├── lib/
│   │   │   └── calc.js            # pnl/qty math, shared with server via mirrored logic
│   │   ├── App.jsx
│   │   └── main.jsx
│   └── package.json
├── server/
│   ├── routes/
│   │   ├── trades.js
│   │   ├── upload.js
│   │   └── marketdata.js
│   ├── parsers/
│   │   ├── index.js                # detects broker format, dispatches
│   │   ├── zerodha.js
│   │   ├── upstox.js
│   │   ├── groww.js
│   │   └── generic.js              # manual column-mapping fallback
│   ├── services/
│   │   └── marketDataService.js
│   ├── db/
│   │   └── schema.prisma
│   ├── index.js
│   └── package.json
├── .env.example
└── README.md
```

## 4. Data model (Prisma schema, `server/db/schema.prisma`)

```prisma
model Trade {
  id          String   @id @default(uuid())
  date        DateTime
  stock       String
  exchange    String   // "NSE" | "BSE"
  segment     String   // "Equity" | "Futures" | "Options"
  direction   String   // "Long" | "Short"
  buyPrice    Float
  sellPrice   Float?   // null = open position
  lotSize     Int      @default(1)
  lots        Float
  charges     Float    @default(0)
  notes       String?
  strategy    String?
  source      String   @default("manual")  // "manual" | broker name
  importId    String?  // links back to the ImportBatch this row came from
  pnl         Float?   // computed and stored on write, not just derived client-side
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}

model ImportBatch {
  id         String   @id @default(uuid())
  broker     String
  filename   String
  rowCount   Int
  createdAt  DateTime @default(now())
}
```

**P&L calculation (implement identically on client for optimistic UI and server for source of truth):**
```
qty = lotSize * lots
pnl = direction === "Short"
  ? (buyPrice - sellPrice) * qty - charges
  : (sellPrice - buyPrice) * qty - charges
// pnl is null while sellPrice is null (open position)
```

## 5. File upload & parsing flow

1. User drags/drops or selects a file on the Upload page.
2. File goes to `POST /api/upload` as multipart form data.
3. Server detects file type (csv/xlsx/pdf) and tries each known broker parser (`parsers/zerodha.js`, `upstox.js`, `groww.js`) against the header row until one matches (each parser exports a `detect(headers)` and `parse(rows)` function).
4. If no parser matches, fall back to `parsers/generic.js`, which returns raw headers + rows so the frontend can render `ColumnMapper.jsx` — a UI where the user maps their columns to our fields (date, stock, buyPrice, sellPrice, lots, lotSize, charges).
5. Either way, server responds with a **preview**: parsed rows in our `Trade` shape, not yet written to the DB.
6. Frontend shows `UploadPreviewTable.jsx` — editable, so the user can fix a misparsed row before committing.
7. On confirm, `POST /api/upload/commit` writes the rows as `Trade` records plus one `ImportBatch` record.

Build the Zerodha tradebook parser first (most common broker) — reference format has columns like `symbol, isin, trade_date, exchange, segment, series, trade_type, auction, quantity, price, trade_id, order_id, order_execution_time`. Note Zerodha's tradebook lists buy and sell as **separate rows** per symbol/date — the parser must pair a buy row with its matching sell row (same symbol, closest subsequent sell) to form one `Trade`. Flag unmatched rows (still-open positions) instead of discarding them.

## 6. Market data service (`server/services/marketDataService.js`)

Define one interface and build everything else against it — do not let any component talk to a market data provider directly:

```js
// returns OHLC candles for a symbol between a date range
async function getCandles({ symbol, exchange, from, to, interval }) { ... }
```

Start with whatever free/limited data source is available (document its rate limits and gaps in the README). The interface must not change when we later swap in a paid provider like Kite Connect — only the implementation inside this file changes. Never let an API key reach the client; all market data requests are proxied through `GET /api/marketdata/:symbol`.

On `TradeDetail.jsx`, render candles via `lightweight-charts` and overlay two markers: entry price/date (green) and exit price/date (red), using the library's series markers API.

## 7. Pages

- **Dashboard** — net P&L, win rate, equity curve (recharts), open vs closed count, charges paid, recent trades list
- **Journal** — full trade table, sortable/filterable by symbol/segment/date, spreadsheet-style inline add row at top (see below), click a row to expand/edit, link into Trade Detail
- **Trade Detail** — `TradeChart.jsx` for that symbol with entry/exit markers, trade fields, notes, editable
- **Upload** — dropzone → parsing → preview/column-mapping → commit
- **Analytics** — breakdown by strategy and by segment, win/loss streaks, monthly P&L bar chart

## 8. UI/UX direction

- Modern, clean, data-dense but not cluttered — this is a tool used daily, optimize for scanning speed over decoration
- INR formatting everywhere: `₹` symbol, Indian digit grouping (`toLocaleString('en-IN')`), never `$`
- Green for gains, red for losses — used functionally, consistently, nowhere else
- The Journal table should support fast entry: an always-visible input row at the top of the table (not a separate modal form) so logging a trade doesn't interrupt the scan of existing ones
- Loading and empty states for every async view (upload parsing, chart loading, empty journal)
- Mobile-responsive is a nice-to-have, not a blocker — this is primarily a desktop tool

## 9. Build order (do not skip ahead)

1. Scaffold repo structure above, Prisma schema, basic Express server with health check
2. Manual trade CRUD end-to-end (API + Journal page with inline add/edit row + Dashboard stat cards) — get the core loop working with zero file upload or charts
3. Upload flow: generic CSV parser + column mapper + preview + commit (prove the pipeline before adding broker-specific parsers)
4. Zerodha parser, tested against real sample export
5. `marketDataService` with a placeholder/free data source + `TradeChart.jsx` wired to it
6. Trade Detail page combining chart + trade fields
7. Analytics page
8. Additional broker parsers (Upstox, Groww), PDF parser, polish

Do not build charts or file parsing before the manual CRUD loop works — each step should leave the app in a runnable, demoable state.

## 10. Environment variables (`.env.example`)

```
DATABASE_URL=file:./dev.db
MARKET_DATA_API_KEY=
MARKET_DATA_PROVIDER=      # e.g. "kite" | "placeholder"
PORT=4000
```

## 11. Conventions

- Functional React components, hooks only, no class components
- Keep P&L/qty math in one shared module per side (`client/src/lib/calc.js`, mirrored logic server-side) — never recompute inline in a component
- All money values stored and transmitted as numbers (paise-safe floats), formatted only at render time
- Every new API route gets a corresponding function in `client/src/api/client.js` — components never call `fetch` directly
- Commit after each build-order step above, with a message describing what became demoable
