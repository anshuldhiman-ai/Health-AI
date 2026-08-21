-- CreateTable
CREATE TABLE "Trade" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "date" DATETIME NOT NULL,
    "stock" TEXT NOT NULL,
    "exchange" TEXT NOT NULL,
    "segment" TEXT NOT NULL,
    "direction" TEXT NOT NULL,
    "buyPrice" REAL NOT NULL,
    "sellPrice" REAL,
    "lotSize" INTEGER NOT NULL DEFAULT 1,
    "lots" REAL NOT NULL,
    "charges" REAL NOT NULL DEFAULT 0,
    "notes" TEXT,
    "strategy" TEXT,
    "source" TEXT NOT NULL DEFAULT 'manual',
    "importId" TEXT,
    "pnl" REAL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "ImportBatch" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "broker" TEXT NOT NULL,
    "filename" TEXT NOT NULL,
    "rowCount" INTEGER NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
