import { useEffect, useRef, useState } from "react";
import { createChart } from "lightweight-charts";
import { api } from "../api/client.js";

// Candlestick chart for a single trade's symbol. Overlays entry (green up-arrow)
// and exit (red down-arrow) markers at the trade's date/price.
//
// Props:
//   symbol, exchange      — what to chart
//   entryDate, entryPrice — for the green marker
//   exitDate, exitPrice   — optional — for the red marker (omitted for open positions)
//   height                — px height, defaults to 400
export default function TradeChart({
  symbol,
  exchange = "NSE",
  entryDate,
  entryPrice,
  exitDate,
  exitPrice,
  height = 400,
}) {
  const containerRef = useRef(null);
  const chartRef = useRef(null);
  const seriesRef = useRef(null);
  const [err, setErr] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!containerRef.current || !symbol || !entryDate) return;

    // Range: a generous window around the trade. For an open trade we anchor on
    // entryDate and extend through "today".
    const fromDate = new Date(entryDate);
    const toDate = exitDate ? new Date(exitDate) : new Date();
    // Pad ±30 calendar days for context.
    fromDate.setDate(fromDate.getDate() - 30);
    toDate.setDate(toDate.getDate() + 5);

    const from = fromDate.toISOString().slice(0, 10);
    const to = toDate.toISOString().slice(0, 10);

    let disposed = false;

    api
      .getCandles({ symbol, exchange, from, to, interval: "1d" })
      .then(({ candles }) => {
        if (disposed) return;
        const chart = createChart(containerRef.current, {
          width: containerRef.current.clientWidth,
          height,
          layout: {
            background: { color: "#0b0d10" },
            textColor: "#9ca3af",
          },
          grid: {
            vertLines: { color: "#1f2937" },
            horzLines: { color: "#1f2937" },
          },
          timeScale: {
            borderColor: "#1f2937",
            timeVisible: true,
            secondsVisible: false,
          },
          rightPriceScale: {
            borderColor: "#1f2937",
          },
          crosshair: {
            vertLine: { color: "#4b5563", labelBackgroundColor: "#111827" },
            horzLine: { color: "#4b5563", labelBackgroundColor: "#111827" },
          },
        });
        chartRef.current = chart;

        const series = chart.addCandlestickSeries({
          upColor: "#16a34a",
          downColor: "#dc2626",
          borderUpColor: "#16a34a",
          borderDownColor: "#dc2626",
          wickUpColor: "#16a34a",
          wickDownColor: "#dc2626",
        });
        seriesRef.current = series;

        // lightweight-charts requires ascending time strings.
        const data = candles
          .slice()
          .sort((a, b) => (a.time < b.time ? -1 : 1))
          .map((c) => ({
            time: c.time,
            open: c.open,
            high: c.high,
            low: c.low,
            close: c.close,
          }));
        series.setData(data);

        // Markers — entry (green up arrow), exit (red down arrow).
        const markers = [];
        if (entryDate && entryPrice) {
          markers.push({
            time: entryDate.slice(0, 10),
            position: "belowBar",
            color: "#16a34a",
            shape: "arrowUp",
            text: `Entry ${entryPrice}`,
          });
        }
        if (exitDate && exitPrice) {
          markers.push({
            time: exitDate.slice(0, 10),
            position: "aboveBar",
            color: "#dc2626",
            shape: "arrowDown",
            text: `Exit ${exitPrice}`,
          });
        }
        if (markers.length) series.setMarkers(markers);

        chart.timeScale().fitContent();
        setLoading(false);
      })
      .catch((e) => {
        setErr(String(e.message || e));
        setLoading(false);
      });

    const onResize = () => {
      if (chartRef.current && containerRef.current) {
        chartRef.current.applyOptions({ width: containerRef.current.clientWidth });
      }
    };
    window.addEventListener("resize", onResize);

    return () => {
      disposed = true;
      window.removeEventListener("resize", onResize);
      if (chartRef.current) {
        chartRef.current.remove();
        chartRef.current = null;
      }
    };
  }, [symbol, exchange, entryDate, entryPrice, exitDate, exitPrice, height]);

  return (
    <div className="relative rounded-lg border border-neutral-800 bg-neutral-900 p-2">
      <div ref={containerRef} style={{ height }} />
      {loading ? (
        <div className="absolute inset-0 flex items-center justify-center text-neutral-500 text-sm">
          Loading chart…
        </div>
      ) : null}
      {err ? (
        <div className="absolute inset-0 flex items-center justify-center text-loss text-sm">
          {err}
        </div>
      ) : null}
    </div>
  );
}
