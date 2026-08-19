# Trading Journal

A trading journal web app for an Indian retail trader (NSE/BSE, equity + F&O).

Upload your broker's trade file (CSV/Excel/PDF) and the app parses it into structured trade records. Each trade opens to a chart with your entry and exit marked. Currency is always INR (₹).

See [CLAUDE.md](./CLAUDE.md) for the full specification.

## Stack

- Frontend: React (Vite), Tailwind CSS, lightweight-charts, recharts
- Backend: Node.js + Express
- DB: SQLite via Prisma (schema is Postgres-compatible)
- Parsers: papaparse (CSV), xlsx (Excel), pdf-parse (PDF)

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

## Build order

See CLAUDE.md §9. Steps leave the app runnable and demoable at each stage.
