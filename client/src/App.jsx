import { NavLink, Route, Routes } from "react-router-dom";
import Dashboard from "./pages/Dashboard.jsx";
import Journal from "./pages/Journal.jsx";
import TradeDetail from "./pages/TradeDetail.jsx";
import Upload from "./pages/Upload.jsx";
import Analytics from "./pages/Analytics.jsx";

const navItems = [
  { to: "/", label: "Dashboard", end: true },
  { to: "/journal", label: "Journal" },
  { to: "/upload", label: "Upload" },
  { to: "/analytics", label: "Analytics" },
];

export default function App() {
  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b border-neutral-800 bg-neutral-950">
        <div className="max-w-7xl mx-auto px-6 py-3 flex items-center justify-between">
          <div className="font-semibold tracking-tight">Trading Journal</div>
          <nav className="flex gap-1">
            {navItems.map((n) => (
              <NavLink
                key={n.to}
                to={n.to}
                end={n.end}
                className={({ isActive }) =>
                  `px-3 py-1.5 rounded text-sm ${
                    isActive ? "bg-neutral-800 text-white" : "text-neutral-400 hover:text-white"
                  }`
                }
              >
                {n.label}
              </NavLink>
            ))}
          </nav>
        </div>
      </header>
      <main className="flex-1 max-w-7xl w-full mx-auto px-6 py-6">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/journal" element={<Journal />} />
          <Route path="/upload" element={<Upload />} />
          <Route path="/analytics" element={<Analytics />} />
          <Route path="/trade/:id" element={<TradeDetail />} />
        </Routes>
      </main>
    </div>
  );
}
